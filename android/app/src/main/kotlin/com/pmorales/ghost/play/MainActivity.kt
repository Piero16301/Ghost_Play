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

                MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                        .setMethodCallHandler { call, result ->
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
                                                                        applicationContext
                                                                                .contentResolver
                                                                                .persistedUriPermissions
                                                                val rootUri =
                                                                        persistedUris
                                                                                .find {
                                                                                        val decoded =
                                                                                                Uri.decode(
                                                                                                        it.uri
                                                                                                                .toString()
                                                                                                )
                                                                                        decoded.contains(
                                                                                                uriString
                                                                                        )
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

                                                                val rootDocId =
                                                                        DocumentsContract
                                                                                .getTreeDocumentId(
                                                                                        rootUri
                                                                                )
                                                                val rootChildrenUri =
                                                                        DocumentsContract
                                                                                .buildChildDocumentsUriUsingTree(
                                                                                        rootUri,
                                                                                        rootDocId
                                                                                )

                                                                val projection =
                                                                        arrayOf(
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_DOCUMENT_ID,
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_DISPLAY_NAME,
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_MIME_TYPE,
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_LAST_MODIFIED,
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_SIZE
                                                                        )

                                                                var voiceNotesDocId = rootDocId
                                                                applicationContext.contentResolver
                                                                        .query(
                                                                                rootChildrenUri,
                                                                                projection,
                                                                                null,
                                                                                null,
                                                                                null
                                                                        )
                                                                        ?.use { cursor ->
                                                                                val idIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_DOCUMENT_ID
                                                                                        )
                                                                                val nameIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_DISPLAY_NAME
                                                                                        )
                                                                                val mimeIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_MIME_TYPE
                                                                                        )

                                                                                while (cursor.moveToNext()) {
                                                                                        val mime =
                                                                                                cursor.getString(
                                                                                                        mimeIdx
                                                                                                )
                                                                                        val name =
                                                                                                cursor.getString(
                                                                                                        nameIdx
                                                                                                )
                                                                                                        ?: ""
                                                                                        if (mime ==
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .MIME_TYPE_DIR &&
                                                                                                        name ==
                                                                                                                "WhatsApp Voice Notes"
                                                                                        ) {
                                                                                                voiceNotesDocId =
                                                                                                        cursor.getString(
                                                                                                                idIdx
                                                                                                        )
                                                                                                break
                                                                                        }
                                                                                }
                                                                        }

                                                                val voiceNotesChildrenUri =
                                                                        DocumentsContract
                                                                                .buildChildDocumentsUriUsingTree(
                                                                                        rootUri,
                                                                                        voiceNotesDocId
                                                                                )

                                                                data class FileInfo(
                                                                        val uri: Uri,
                                                                        val name: String,
                                                                        val lastModified: Long,
                                                                        val size: Long
                                                                )
                                                                val weekFolders =
                                                                        mutableListOf<
                                                                                Triple<
                                                                                        String,
                                                                                        String,
                                                                                        Long>>()

                                                                applicationContext.contentResolver
                                                                        .query(
                                                                                voiceNotesChildrenUri,
                                                                                projection,
                                                                                null,
                                                                                null,
                                                                                null
                                                                        )
                                                                        ?.use { cursor ->
                                                                                val idIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_DOCUMENT_ID
                                                                                        )
                                                                                val nameIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_DISPLAY_NAME
                                                                                        )
                                                                                val mimeIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_MIME_TYPE
                                                                                        )
                                                                                val dateIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_LAST_MODIFIED
                                                                                        )

                                                                                while (cursor.moveToNext()) {
                                                                                        val mime =
                                                                                                cursor.getString(
                                                                                                        mimeIdx
                                                                                                )
                                                                                        if (mime ==
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .MIME_TYPE_DIR
                                                                                        ) {
                                                                                                val docId =
                                                                                                        cursor.getString(
                                                                                                                idIdx
                                                                                                        )
                                                                                                val name =
                                                                                                        cursor.getString(
                                                                                                                nameIdx
                                                                                                        )
                                                                                                                ?: ""
                                                                                                val date =
                                                                                                        cursor.getLong(
                                                                                                                dateIdx
                                                                                                        )
                                                                                                weekFolders
                                                                                                        .add(
                                                                                                                Triple(
                                                                                                                        docId,
                                                                                                                        name,
                                                                                                                        date
                                                                                                                )
                                                                                                        )
                                                                                        }
                                                                                }
                                                                        }

                                                                weekFolders.sortByDescending {
                                                                        it.second
                                                                }
                                                                val foldersToScan =
                                                                        weekFolders.take(
                                                                                weeksToScan
                                                                        )

                                                                val allOpusFiles =
                                                                        mutableListOf<FileInfo>()

                                                                foldersToScan.forEach { folder ->
                                                                        val folderDocId =
                                                                                folder.first
                                                                        val folderChildrenUri =
                                                                                DocumentsContract
                                                                                        .buildChildDocumentsUriUsingTree(
                                                                                                rootUri,
                                                                                                folderDocId
                                                                                        )

                                                                        applicationContext
                                                                                .contentResolver
                                                                                .query(
                                                                                        folderChildrenUri,
                                                                                        projection,
                                                                                        null,
                                                                                        null,
                                                                                        null
                                                                                )
                                                                                ?.use { cursor ->
                                                                                        val idIdx =
                                                                                                cursor.getColumnIndexOrThrow(
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .COLUMN_DOCUMENT_ID
                                                                                                )
                                                                                        val nameIdx =
                                                                                                cursor.getColumnIndexOrThrow(
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .COLUMN_DISPLAY_NAME
                                                                                                )
                                                                                        val dateIdx =
                                                                                                cursor.getColumnIndexOrThrow(
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .COLUMN_LAST_MODIFIED
                                                                                                )
                                                                                        val sizeIdx =
                                                                                                cursor.getColumnIndexOrThrow(
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .COLUMN_SIZE
                                                                                                )

                                                                                        while (cursor.moveToNext()) {
                                                                                                val name =
                                                                                                        cursor.getString(
                                                                                                                nameIdx
                                                                                                        )
                                                                                                                ?: ""
                                                                                                if (name.endsWith(
                                                                                                                ".opus"
                                                                                                        )
                                                                                                ) {
                                                                                                        val docId =
                                                                                                                cursor.getString(
                                                                                                                        idIdx
                                                                                                                )
                                                                                                        val date =
                                                                                                                cursor.getLong(
                                                                                                                        dateIdx
                                                                                                                )
                                                                                                        val size =
                                                                                                                cursor.getLong(
                                                                                                                        sizeIdx
                                                                                                                )
                                                                                                        val fileUri =
                                                                                                                DocumentsContract
                                                                                                                        .buildDocumentUriUsingTree(
                                                                                                                                rootUri,
                                                                                                                                docId
                                                                                                                        )
                                                                                                        allOpusFiles
                                                                                                                .add(
                                                                                                                        FileInfo(
                                                                                                                                fileUri,
                                                                                                                                name,
                                                                                                                                date,
                                                                                                                                size
                                                                                                                        )
                                                                                                                )
                                                                                                }
                                                                                        }
                                                                                }
                                                                }

                                                                val topFiles =
                                                                        allOpusFiles
                                                                                .sortedByDescending {
                                                                                        it.lastModified
                                                                                }

                                                                val resultList =
                                                                        mutableListOf<
                                                                                Map<String, Any>>()
                                                                val retriever =
                                                                        MediaMetadataRetriever()

                                                                for (file in topFiles) {
                                                                        var durationMs: Long = 0
                                                                        try {
                                                                                retriever
                                                                                        .setDataSource(
                                                                                                applicationContext,
                                                                                                file.uri
                                                                                        )
                                                                                val durationStr =
                                                                                        retriever
                                                                                                .extractMetadata(
                                                                                                        MediaMetadataRetriever
                                                                                                                .METADATA_KEY_DURATION
                                                                                                )
                                                                                durationMs =
                                                                                        durationStr
                                                                                                ?.toLongOrNull()
                                                                                                ?: 0L
                                                                        } catch (e: Exception) {}

                                                                        val fileData =
                                                                                mapOf(
                                                                                        "uri" to
                                                                                                file.uri
                                                                                                        .toString(),
                                                                                        "name" to
                                                                                                file.name,
                                                                                        "date" to
                                                                                                file.lastModified,
                                                                                        "size" to
                                                                                                file.size,
                                                                                        "duration" to
                                                                                                durationMs
                                                                                )
                                                                        resultList.add(fileData)
                                                                }
                                                                retriever.release()

                                                                runOnUiThread {
                                                                        result.success(resultList)
                                                                }
                                                        } catch (e: Exception) {
                                                                runOnUiThread {
                                                                        result.error(
                                                                                "READ_ERROR",
                                                                                e.message,
                                                                                null
                                                                        )
                                                                }
                                                        }
                                                }
                                                .start()
                                } else if (call.method == "getRecentStates") {
                                        val uriString = call.argument<String>("uri")

                                        if (uriString == null) {
                                                result.error("INVALID_URI", "URI is null", null)
                                                return@setMethodCallHandler
                                        }

                                        Thread {
                                                        try {
                                                                val persistedUris =
                                                                        applicationContext
                                                                                .contentResolver
                                                                                .persistedUriPermissions
                                                                val rootUri =
                                                                        persistedUris
                                                                                .find {
                                                                                        val decoded =
                                                                                                Uri.decode(
                                                                                                        it.uri
                                                                                                                .toString()
                                                                                                )
                                                                                        decoded.contains(
                                                                                                uriString
                                                                                        )
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

                                                                val rootDocId =
                                                                        DocumentsContract
                                                                                .getTreeDocumentId(
                                                                                        rootUri
                                                                                )
                                                                val rootChildrenUri =
                                                                        DocumentsContract
                                                                                .buildChildDocumentsUriUsingTree(
                                                                                        rootUri,
                                                                                        rootDocId
                                                                                )

                                                                val projection =
                                                                        arrayOf(
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_DOCUMENT_ID,
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_DISPLAY_NAME,
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_MIME_TYPE,
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_LAST_MODIFIED,
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_SIZE
                                                                        )

                                                                var statusesDocId: String? = null

                                                                applicationContext.contentResolver
                                                                        .query(
                                                                                rootChildrenUri,
                                                                                projection,
                                                                                null,
                                                                                null,
                                                                                null
                                                                        )
                                                                        ?.use { cursor ->
                                                                                val idIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_DOCUMENT_ID
                                                                                        )
                                                                                val nameIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_DISPLAY_NAME
                                                                                        )
                                                                                val mimeIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_MIME_TYPE
                                                                                        )

                                                                                while (cursor.moveToNext()) {
                                                                                        val mime =
                                                                                                cursor.getString(
                                                                                                        mimeIdx
                                                                                                )
                                                                                        if (mime ==
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .MIME_TYPE_DIR
                                                                                        ) {
                                                                                                val name =
                                                                                                        cursor.getString(
                                                                                                                nameIdx
                                                                                                        )
                                                                                                                ?: ""
                                                                                                if (name ==
                                                                                                                ".Statuses"
                                                                                                ) {
                                                                                                        statusesDocId =
                                                                                                                cursor.getString(
                                                                                                                        idIdx
                                                                                                                )
                                                                                                        break
                                                                                                }
                                                                                        }
                                                                                }
                                                                        }

                                                                if (statusesDocId == null) {
                                                                        runOnUiThread {
                                                                                result.success(
                                                                                        emptyList<
                                                                                                Map<
                                                                                                        String,
                                                                                                        Any>>()
                                                                                )
                                                                        }
                                                                        return@Thread
                                                                }

                                                                val statusesChildrenUri =
                                                                        DocumentsContract
                                                                                .buildChildDocumentsUriUsingTree(
                                                                                        rootUri,
                                                                                        statusesDocId
                                                                                )
                                                                val allStatusFiles =
                                                                        mutableListOf<
                                                                                Map<String, Any>>()
                                                                val retriever =
                                                                        MediaMetadataRetriever()

                                                                applicationContext.contentResolver
                                                                        .query(
                                                                                statusesChildrenUri,
                                                                                projection,
                                                                                null,
                                                                                null,
                                                                                null
                                                                        )
                                                                        ?.use { cursor ->
                                                                                val idIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_DOCUMENT_ID
                                                                                        )
                                                                                val nameIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_DISPLAY_NAME
                                                                                        )
                                                                                val mimeIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_MIME_TYPE
                                                                                        )
                                                                                val dateIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_LAST_MODIFIED
                                                                                        )
                                                                                val sizeIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_SIZE
                                                                                        )

                                                                                while (cursor.moveToNext()) {
                                                                                        val name =
                                                                                                cursor.getString(
                                                                                                        nameIdx
                                                                                                )
                                                                                                        ?: ""
                                                                                        val mime =
                                                                                                cursor.getString(
                                                                                                        mimeIdx
                                                                                                )
                                                                                                        ?: ""

                                                                                        if (name.endsWith(
                                                                                                        ".jpg"
                                                                                                ) ||
                                                                                                        name.endsWith(
                                                                                                                ".mp4"
                                                                                                        )
                                                                                        ) {
                                                                                                val docId =
                                                                                                        cursor.getString(
                                                                                                                idIdx
                                                                                                        )
                                                                                                val date =
                                                                                                        cursor.getLong(
                                                                                                                dateIdx
                                                                                                        )
                                                                                                val size =
                                                                                                        cursor.getLong(
                                                                                                                sizeIdx
                                                                                                        )
                                                                                                val fileUri =
                                                                                                        DocumentsContract
                                                                                                                .buildDocumentUriUsingTree(
                                                                                                                        rootUri,
                                                                                                                        docId
                                                                                                                )
                                                                                                val isVideo =
                                                                                                        name.endsWith(
                                                                                                                ".mp4"
                                                                                                        ) ||
                                                                                                                mime.startsWith(
                                                                                                                        "video/"
                                                                                                                )
                                                                                                var durationMs:
                                                                                                        Long =
                                                                                                        0

                                                                                                if (isVideo
                                                                                                ) {
                                                                                                        try {
                                                                                                                retriever
                                                                                                                        .setDataSource(
                                                                                                                                applicationContext,
                                                                                                                                fileUri
                                                                                                                        )
                                                                                                                val durationStr =
                                                                                                                        retriever
                                                                                                                                .extractMetadata(
                                                                                                                                        MediaMetadataRetriever
                                                                                                                                                .METADATA_KEY_DURATION
                                                                                                                                )
                                                                                                                durationMs =
                                                                                                                        durationStr
                                                                                                                                ?.toLongOrNull()
                                                                                                                                ?: 0L
                                                                                                        } catch (
                                                                                                                e:
                                                                                                                        Exception) {}
                                                                                                }

                                                                                                allStatusFiles
                                                                                                        .add(
                                                                                                                mapOf(
                                                                                                                        "uri" to
                                                                                                                                fileUri.toString(),
                                                                                                                        "name" to
                                                                                                                                name,
                                                                                                                        "date" to
                                                                                                                                date,
                                                                                                                        "size" to
                                                                                                                                size,
                                                                                                                        "is_video" to
                                                                                                                                isVideo,
                                                                                                                        "duration" to
                                                                                                                                durationMs
                                                                                                                )
                                                                                                        )
                                                                                        }
                                                                                }
                                                                        }
                                                                retriever.release()

                                                                val sortedFiles =
                                                                        allStatusFiles
                                                                                .sortedByDescending {
                                                                                        it[
                                                                                                "date"] as
                                                                                                Long
                                                                                }
                                                                runOnUiThread {
                                                                        result.success(sortedFiles)
                                                                }
                                                        } catch (e: Exception) {
                                                                runOnUiThread {
                                                                        result.error(
                                                                                "READ_ERROR",
                                                                                e.message,
                                                                                null
                                                                        )
                                                                }
                                                        }
                                                }
                                                .start()
                                } else if (call.method == "getThumbnailBytes") {
                                        val uriString = call.argument<String>("uri")
                                        val isVideo = call.argument<Boolean>("isVideo") ?: false

                                        if (uriString == null) {
                                                result.error("INVALID_URI", "URI is null", null)
                                                return@setMethodCallHandler
                                        }

                                        Thread {
                                                        try {
                                                                val uri = Uri.parse(uriString)
                                                                var bitmap:
                                                                        android.graphics.Bitmap? =
                                                                        null

                                                                if (android.os.Build.VERSION
                                                                                .SDK_INT >=
                                                                                android.os.Build
                                                                                        .VERSION_CODES
                                                                                        .Q
                                                                ) {
                                                                        try {
                                                                                bitmap =
                                                                                        applicationContext
                                                                                                .contentResolver
                                                                                                .loadThumbnail(
                                                                                                        uri,
                                                                                                        android.util
                                                                                                                .Size(
                                                                                                                        512,
                                                                                                                        512
                                                                                                                ),
                                                                                                        null
                                                                                                )
                                                                        } catch (e: Exception) {}
                                                                }

                                                                if (bitmap == null) {
                                                                        if (isVideo) {
                                                                                val retriever =
                                                                                        MediaMetadataRetriever()
                                                                                try {
                                                                                        retriever
                                                                                                .setDataSource(
                                                                                                        applicationContext,
                                                                                                        uri
                                                                                                )
                                                                                        bitmap =
                                                                                                retriever
                                                                                                        .getFrameAtTime(
                                                                                                                0
                                                                                                        )
                                                                                } catch (
                                                                                        e:
                                                                                                Exception) {} finally {
                                                                                        retriever
                                                                                                .release()
                                                                                }
                                                                        } else {
                                                                                val inputStream =
                                                                                        applicationContext
                                                                                                .contentResolver
                                                                                                .openInputStream(
                                                                                                        uri
                                                                                                )
                                                                                if (inputStream !=
                                                                                                null
                                                                                ) {
                                                                                        val options =
                                                                                                android.graphics
                                                                                                        .BitmapFactory
                                                                                                        .Options()
                                                                                        options.inSampleSize =
                                                                                                2
                                                                                        bitmap =
                                                                                                android.graphics
                                                                                                        .BitmapFactory
                                                                                                        .decodeStream(
                                                                                                                inputStream,
                                                                                                                null,
                                                                                                                options
                                                                                                        )
                                                                                        inputStream
                                                                                                .close()
                                                                                }
                                                                        }
                                                                }

                                                                if (bitmap != null) {
                                                                        val stream =
                                                                                java.io
                                                                                        .ByteArrayOutputStream()
                                                                        bitmap.compress(
                                                                                android.graphics
                                                                                        .Bitmap
                                                                                        .CompressFormat
                                                                                        .JPEG,
                                                                                80,
                                                                                stream
                                                                        )
                                                                        val bytes =
                                                                                stream.toByteArray()
                                                                        runOnUiThread {
                                                                                result.success(
                                                                                        bytes
                                                                                )
                                                                        }
                                                                } else {
                                                                        runOnUiThread {
                                                                                result.error(
                                                                                        "THUMBNAIL_ERROR",
                                                                                        "Could not generate thumbnail",
                                                                                        null
                                                                                )
                                                                        }
                                                                }
                                                        } catch (e: Exception) {
                                                                runOnUiThread {
                                                                        result.error(
                                                                                "THUMBNAIL_ERROR",
                                                                                e.message,
                                                                                null
                                                                        )
                                                                }
                                                        }
                                                }
                                                .start()
                                } else if (call.method == "cacheFile") {
                                        val uriString = call.argument<String>("uri")
                                        val fileName =
                                                call.argument<String>("fileName") ?: "temp_file"

                                        if (uriString == null) {
                                                result.error("INVALID_URI", "URI is null", null)
                                                return@setMethodCallHandler
                                        }

                                        Thread {
                                                        try {
                                                                val uri = Uri.parse(uriString)
                                                                val inputStream =
                                                                        applicationContext
                                                                                .contentResolver
                                                                                .openInputStream(
                                                                                        uri
                                                                                )

                                                                if (inputStream != null) {
                                                                        val tempFile =
                                                                                java.io.File(
                                                                                        applicationContext
                                                                                                .cacheDir,
                                                                                        fileName
                                                                                )
                                                                        val outputStream =
                                                                                java.io
                                                                                        .FileOutputStream(
                                                                                                tempFile
                                                                                        )

                                                                        val buffer = ByteArray(4096)
                                                                        var bytesRead: Int
                                                                        while (inputStream.read(
                                                                                        buffer
                                                                                )
                                                                                .also {
                                                                                        bytesRead =
                                                                                                it
                                                                                } != -1) {
                                                                                outputStream.write(
                                                                                        buffer,
                                                                                        0,
                                                                                        bytesRead
                                                                                )
                                                                        }

                                                                        outputStream.flush()
                                                                        outputStream.close()
                                                                        inputStream.close()

                                                                        runOnUiThread {
                                                                                result.success(
                                                                                        tempFile.absolutePath
                                                                                )
                                                                        }
                                                                } else {
                                                                        runOnUiThread {
                                                                                result.error(
                                                                                        "CACHE_ERROR",
                                                                                        "InputStream is null",
                                                                                        null
                                                                                )
                                                                        }
                                                                }
                                                        } catch (e: Exception) {
                                                                runOnUiThread {
                                                                        result.error(
                                                                                "CACHE_ERROR",
                                                                                e.message,
                                                                                null
                                                                        )
                                                                }
                                                        }
                                                }
                                                .start()
                                } else if (call.method == "getRecentVideos") {

                                        val uriString = call.argument<String>("uri")
                                        val weeksToScan = call.argument<Int>("weeks") ?: 2

                                        if (uriString == null) {
                                                result.error("INVALID_URI", "URI is null", null)
                                                return@setMethodCallHandler
                                        }

                                        Thread {
                                                        try {
                                                                val persistedUris =
                                                                        applicationContext
                                                                                .contentResolver
                                                                                .persistedUriPermissions
                                                                val rootUri =
                                                                        persistedUris
                                                                                .find {
                                                                                        val decoded =
                                                                                                Uri.decode(
                                                                                                        it.uri
                                                                                                                .toString()
                                                                                                )
                                                                                        decoded.contains(
                                                                                                uriString
                                                                                        )
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

                                                                val rootDocId =
                                                                        DocumentsContract
                                                                                .getTreeDocumentId(
                                                                                        rootUri
                                                                                )
                                                                val rootChildrenUri =
                                                                        DocumentsContract
                                                                                .buildChildDocumentsUriUsingTree(
                                                                                        rootUri,
                                                                                        rootDocId
                                                                                )

                                                                val projection =
                                                                        arrayOf(
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_DOCUMENT_ID,
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_DISPLAY_NAME,
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_MIME_TYPE,
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_LAST_MODIFIED,
                                                                                DocumentsContract
                                                                                        .Document
                                                                                        .COLUMN_SIZE
                                                                        )

                                                                // Navigate to "WhatsApp Video
                                                                // Notes" folder
                                                                var videoNotesDocId = rootDocId
                                                                applicationContext.contentResolver
                                                                        .query(
                                                                                rootChildrenUri,
                                                                                projection,
                                                                                null,
                                                                                null,
                                                                                null
                                                                        )
                                                                        ?.use { cursor ->
                                                                                val idIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_DOCUMENT_ID
                                                                                        )
                                                                                val nameIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_DISPLAY_NAME
                                                                                        )
                                                                                val mimeIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_MIME_TYPE
                                                                                        )

                                                                                while (cursor.moveToNext()) {
                                                                                        val mime =
                                                                                                cursor.getString(
                                                                                                        mimeIdx
                                                                                                )
                                                                                        val name =
                                                                                                cursor.getString(
                                                                                                        nameIdx
                                                                                                )
                                                                                                        ?: ""
                                                                                        if (mime ==
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .MIME_TYPE_DIR &&
                                                                                                        name ==
                                                                                                                "WhatsApp Video Notes"
                                                                                        ) {
                                                                                                videoNotesDocId =
                                                                                                        cursor.getString(
                                                                                                                idIdx
                                                                                                        )
                                                                                                break
                                                                                        }
                                                                                }
                                                                        }

                                                                val videoNotesChildrenUri =
                                                                        DocumentsContract
                                                                                .buildChildDocumentsUriUsingTree(
                                                                                        rootUri,
                                                                                        videoNotesDocId
                                                                                )

                                                                data class FileInfo(
                                                                        val uri: Uri,
                                                                        val name: String,
                                                                        val lastModified: Long,
                                                                        val size: Long
                                                                )

                                                                // Collect weekly sub-folders
                                                                val weekFolders =
                                                                        mutableListOf<
                                                                                Triple<
                                                                                        String,
                                                                                        String,
                                                                                        Long>>()

                                                                applicationContext.contentResolver
                                                                        .query(
                                                                                videoNotesChildrenUri,
                                                                                projection,
                                                                                null,
                                                                                null,
                                                                                null
                                                                        )
                                                                        ?.use { cursor ->
                                                                                val idIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_DOCUMENT_ID
                                                                                        )
                                                                                val nameIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_DISPLAY_NAME
                                                                                        )
                                                                                val mimeIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_MIME_TYPE
                                                                                        )
                                                                                val dateIdx =
                                                                                        cursor.getColumnIndexOrThrow(
                                                                                                DocumentsContract
                                                                                                        .Document
                                                                                                        .COLUMN_LAST_MODIFIED
                                                                                        )

                                                                                while (cursor.moveToNext()) {
                                                                                        val mime =
                                                                                                cursor.getString(
                                                                                                        mimeIdx
                                                                                                )
                                                                                        if (mime ==
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .MIME_TYPE_DIR
                                                                                        ) {
                                                                                                val docId =
                                                                                                        cursor.getString(
                                                                                                                idIdx
                                                                                                        )
                                                                                                val name =
                                                                                                        cursor.getString(
                                                                                                                nameIdx
                                                                                                        )
                                                                                                                ?: ""
                                                                                                val date =
                                                                                                        cursor.getLong(
                                                                                                                dateIdx
                                                                                                        )
                                                                                                weekFolders
                                                                                                        .add(
                                                                                                                Triple(
                                                                                                                        docId,
                                                                                                                        name,
                                                                                                                        date
                                                                                                                )
                                                                                                        )
                                                                                        }
                                                                                }
                                                                        }

                                                                weekFolders.sortByDescending {
                                                                        it.second
                                                                }
                                                                val foldersToScan =
                                                                        weekFolders.take(
                                                                                weeksToScan
                                                                        )

                                                                val allMp4Files =
                                                                        mutableListOf<FileInfo>()

                                                                // Collect .mp4 files from each week
                                                                // folder
                                                                foldersToScan.forEach { folder ->
                                                                        val folderDocId =
                                                                                folder.first
                                                                        val folderChildrenUri =
                                                                                DocumentsContract
                                                                                        .buildChildDocumentsUriUsingTree(
                                                                                                rootUri,
                                                                                                folderDocId
                                                                                        )

                                                                        applicationContext
                                                                                .contentResolver
                                                                                .query(
                                                                                        folderChildrenUri,
                                                                                        projection,
                                                                                        null,
                                                                                        null,
                                                                                        null
                                                                                )
                                                                                ?.use { cursor ->
                                                                                        val idIdx =
                                                                                                cursor.getColumnIndexOrThrow(
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .COLUMN_DOCUMENT_ID
                                                                                                )
                                                                                        val nameIdx =
                                                                                                cursor.getColumnIndexOrThrow(
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .COLUMN_DISPLAY_NAME
                                                                                                )
                                                                                        val dateIdx =
                                                                                                cursor.getColumnIndexOrThrow(
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .COLUMN_LAST_MODIFIED
                                                                                                )
                                                                                        val sizeIdx =
                                                                                                cursor.getColumnIndexOrThrow(
                                                                                                        DocumentsContract
                                                                                                                .Document
                                                                                                                .COLUMN_SIZE
                                                                                                )

                                                                                        while (cursor.moveToNext()) {
                                                                                                val name =
                                                                                                        cursor.getString(
                                                                                                                nameIdx
                                                                                                        )
                                                                                                                ?: ""
                                                                                                if (name.endsWith(
                                                                                                                ".mp4"
                                                                                                        )
                                                                                                ) {
                                                                                                        val docId =
                                                                                                                cursor.getString(
                                                                                                                        idIdx
                                                                                                                )
                                                                                                        val date =
                                                                                                                cursor.getLong(
                                                                                                                        dateIdx
                                                                                                                )
                                                                                                        val size =
                                                                                                                cursor.getLong(
                                                                                                                        sizeIdx
                                                                                                                )
                                                                                                        val fileUri =
                                                                                                                DocumentsContract
                                                                                                                        .buildDocumentUriUsingTree(
                                                                                                                                rootUri,
                                                                                                                                docId
                                                                                                                        )
                                                                                                        allMp4Files
                                                                                                                .add(
                                                                                                                        FileInfo(
                                                                                                                                fileUri,
                                                                                                                                name,
                                                                                                                                date,
                                                                                                                                size
                                                                                                                        )
                                                                                                                )
                                                                                                }
                                                                                        }
                                                                                }
                                                                }

                                                                val topFiles =
                                                                        allMp4Files
                                                                                .sortedByDescending {
                                                                                        it.lastModified
                                                                                }

                                                                val resultList =
                                                                        mutableListOf<
                                                                                Map<String, Any>>()
                                                                val retriever =
                                                                        MediaMetadataRetriever()

                                                                for (file in topFiles) {
                                                                        var durationMs: Long = 0
                                                                        try {
                                                                                retriever
                                                                                        .setDataSource(
                                                                                                applicationContext,
                                                                                                file.uri
                                                                                        )
                                                                                val durationStr =
                                                                                        retriever
                                                                                                .extractMetadata(
                                                                                                        MediaMetadataRetriever
                                                                                                                .METADATA_KEY_DURATION
                                                                                                )
                                                                                durationMs =
                                                                                        durationStr
                                                                                                ?.toLongOrNull()
                                                                                                ?: 0L
                                                                        } catch (e: Exception) {}

                                                                        val fileData =
                                                                                mapOf(
                                                                                        "uri" to
                                                                                                file.uri
                                                                                                        .toString(),
                                                                                        "name" to
                                                                                                file.name,
                                                                                        "date" to
                                                                                                file.lastModified,
                                                                                        "size" to
                                                                                                file.size,
                                                                                        "is_video" to
                                                                                                true,
                                                                                        "duration" to
                                                                                                durationMs
                                                                                )
                                                                        resultList.add(fileData)
                                                                }
                                                                retriever.release()

                                                                runOnUiThread {
                                                                        result.success(resultList)
                                                                }
                                                        } catch (e: Exception) {
                                                                runOnUiThread {
                                                                        result.error(
                                                                                "READ_ERROR",
                                                                                e.message,
                                                                                null
                                                                        )
                                                                }
                                                        }
                                                }
                                                .start()
                                } else {
                                        result.notImplemented()
                                }
                        }
        }
}
