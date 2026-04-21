package com.pmorales.ghost.play

import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.DocumentsContract

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "ghostplay/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            if (call.method == "getRecentAudios") {

                val uriString = call.argument<String>("uri")
                val weeksToScan = call.argument<Int>("weeks") ?: 2

                if (uriString == null) {
                    result.error("INVALID_URI", "URI is null", null)
                    return@setMethodCallHandler
                }

                Thread {
                            try {
                                val persistedUris =
                                        applicationContext.contentResolver.persistedUriPermissions
                                val rootUri =
                                        persistedUris
                                                .find {
                                                    val decoded = Uri.decode(it.uri.toString())
                                                    decoded.contains(uriString)
                                                }
                                                ?.uri

                                if (rootUri == null) {
                                    runOnUiThread {
                                        result.error(
                                                "INVALID_URI",
                                                "No persisted permission for: $uriString",
                                                null
                                        )
                                    }
                                    return@Thread
                                }

                                val rootDocId = DocumentsContract.getTreeDocumentId(rootUri)
                                val rootChildrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(rootUri, rootDocId)

                                val projection = arrayOf(
                                    DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                                    DocumentsContract.Document.COLUMN_MIME_TYPE,
                                    DocumentsContract.Document.COLUMN_LAST_MODIFIED,
                                    DocumentsContract.Document.COLUMN_SIZE
                                )

                                data class FileInfo(val uri: Uri, val name: String, val lastModified: Long, val size: Long)
                                val weekFolders = mutableListOf<Triple<String, String, Long>>()

                                applicationContext.contentResolver.query(rootChildrenUri, projection, null, null, null)?.use { cursor ->
                                    val idIdx = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                                    val nameIdx = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                                    val mimeIdx = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)
                                    val dateIdx = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_LAST_MODIFIED)

                                    while (cursor.moveToNext()) {
                                        val mime = cursor.getString(mimeIdx)
                                        if (mime == DocumentsContract.Document.MIME_TYPE_DIR) {
                                            val docId = cursor.getString(idIdx)
                                            val name = cursor.getString(nameIdx) ?: ""
                                            val date = cursor.getLong(dateIdx)
                                            weekFolders.add(Triple(docId, name, date))
                                        }
                                    }
                                }

                                weekFolders.sortByDescending { it.second }
                                val foldersToScan = weekFolders.take(weeksToScan)

                                val allOpusFiles = mutableListOf<FileInfo>()

                                foldersToScan.forEach { folder ->
                                    val folderDocId = folder.first
                                    val folderChildrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(rootUri, folderDocId)

                                    applicationContext.contentResolver.query(folderChildrenUri, projection, null, null, null)?.use { cursor ->
                                        val idIdx = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                                        val nameIdx = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                                        val dateIdx = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_LAST_MODIFIED)
                                        val sizeIdx = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_SIZE)

                                        while (cursor.moveToNext()) {
                                            val name = cursor.getString(nameIdx) ?: ""
                                            if (name.endsWith(".opus")) {
                                                val docId = cursor.getString(idIdx)
                                                val date = cursor.getLong(dateIdx)
                                                val size = cursor.getLong(sizeIdx)
                                                val fileUri = DocumentsContract.buildDocumentUriUsingTree(rootUri, docId)
                                                allOpusFiles.add(FileInfo(fileUri, name, date, size))
                                            }
                                        }
                                    }
                                }

                                val topFiles = allOpusFiles.sortedByDescending { it.lastModified }

                                val resultList = mutableListOf<Map<String, Any>>()
                                val retriever = MediaMetadataRetriever()

                                for (file in topFiles) {
                                    var durationMs: Long = 0
                                    try {
                                        retriever.setDataSource(applicationContext, file.uri)
                                        val durationStr =
                                                retriever.extractMetadata(
                                                        MediaMetadataRetriever.METADATA_KEY_DURATION
                                                )
                                        durationMs = durationStr?.toLongOrNull() ?: 0L
                                    } catch (e: Exception) {}

                                    val fileData =
                                            mapOf(
                                                    "uri" to file.uri.toString(),
                                                    "name" to file.name,
                                                    "date" to file.lastModified,
                                                    "size" to file.size,
                                                    "duration" to durationMs
                                            )
                                    resultList.add(fileData)
                                }
                                retriever.release()

                                runOnUiThread { result.success(resultList) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("READ_ERROR", e.message, null) }
                            }
                        }
                        .start()
            } else {
                result.notImplemented()
            }
        }
    }
}
