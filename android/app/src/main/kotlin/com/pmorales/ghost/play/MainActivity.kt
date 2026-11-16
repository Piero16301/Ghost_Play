package com.pmorales.ghost.play

import android.content.Context
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Callable
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

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
                                                                                                Uri.decode(
                                                                                                        uriString
                                                                                                )
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

                                                                val voiceNotesDocId =
                                                                        findWhatsAppSubfolderDocId(
                                                                                rootUri,
                                                                                rootDocId,
                                                                                "WhatsApp Voice Notes"
                                                                        )

                                                                if (voiceNotesDocId == null) {
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

                                                                val numericWeekFolders =
                                                                        weekFolders.filter {
                                                                                it.second.isNotEmpty() &&
                                                                                        it.second.all { ch ->
                                                                                                ch.isDigit()
                                                                                        }
                                                                        }
                                                                val sortedWeekFolders =
                                                                        (numericWeekFolders.ifEmpty {
                                                                                weekFolders
                                                                        })
                                                                                .sortedByDescending {
                                                                                        it.second
                                                                                }
                                                                val foldersToScan =
                                                                        sortedWeekFolders.take(
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

                                                                val durations =
                                                                        resolveDurationsParallel(
                                                                                topFiles.map {
                                                                                        Triple(
                                                                                                it.uri,
                                                                                                it.lastModified,
                                                                                                it.size
                                                                                        )
                                                                                }
                                                                        )

                                                                val resultList =
                                                                        topFiles.map { file ->
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
                                                                                                (durations[
                                                                                                        file.uri
                                                                                                                .toString()]
                                                                                                        ?: 0L)
                                                                                )
                                                                        }

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
                                                                                                Uri.decode(
                                                                                                        uriString
                                                                                                )
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

                                                                val statusesDocId =
                                                                        findWhatsAppSubfolderDocId(
                                                                                rootUri,
                                                                                rootDocId,
                                                                                ".Statuses"
                                                                        )

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
                                                                                                Uri.decode(
                                                                                                        uriString
                                                                                                )
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
                                                                val videoNotesDocId =
                                                                        findWhatsAppSubfolderDocId(
                                                                                rootUri,
                                                                                rootDocId,
                                                                                "WhatsApp Video Notes"
                                                                        )

                                                                if (videoNotesDocId == null) {
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

                                                                val numericWeekFolders =
                                                                        weekFolders.filter {
                                                                                it.second.isNotEmpty() &&
                                                                                        it.second.all { ch ->
                                                                                                ch.isDigit()
                                                                                        }
                                                                        }
                                                                val sortedWeekFolders =
                                                                        (numericWeekFolders.ifEmpty {
                                                                                weekFolders
                                                                        })
                                                                                .sortedByDescending {
                                                                                        it.second
                                                                                }
                                                                val foldersToScan =
                                                                        sortedWeekFolders.take(
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

                                                                val durations =
                                                                        resolveDurationsParallel(
                                                                                topFiles.map {
                                                                                        Triple(
                                                                                                it.uri,
                                                                                                it.lastModified,
                                                                                                it.size
                                                                                        )
                                                                                }
                                                                        )

                                                                val resultList =
                                                                        topFiles.map { file ->
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
                                                                                                (durations[
                                                                                                        file.uri
                                                                                                                .toString()]
                                                                                                        ?: 0L)
                                                                                )
                                                                        }

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

        private fun findWhatsAppSubfolderDocId(
                rootUri: Uri,
                rootDocId: String,
                targetName: String
        ): String? {
                if (rootDocId.endsWith("/$targetName") || rootDocId.endsWith(":$targetName")) {
                        return rootDocId
                }

                val intermediateDirs = setOf("Android", "media", "com.whatsapp", "WhatsApp", "Media")
                val queue = ArrayDeque<Pair<String, Int>>()
                queue.add(rootDocId to 0)
                val projection =
                        arrayOf(
                                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                                DocumentsContract.Document.COLUMN_MIME_TYPE
                        )

                while (queue.isNotEmpty()) {
                        val (currentDocId, depth) = queue.removeFirst()
                        val childrenUri =
                                DocumentsContract.buildChildDocumentsUriUsingTree(
                                        rootUri,
                                        currentDocId
                                )

                        applicationContext.contentResolver
                                .query(childrenUri, projection, null, null, null)
                                ?.use { cursor ->
                                        val idIdx =
                                                cursor.getColumnIndexOrThrow(
                                                        DocumentsContract.Document.COLUMN_DOCUMENT_ID
                                                )
                                        val nameIdx =
                                                cursor.getColumnIndexOrThrow(
                                                        DocumentsContract.Document.COLUMN_DISPLAY_NAME
                                                )
                                        val mimeIdx =
                                                cursor.getColumnIndexOrThrow(
                                                        DocumentsContract.Document.COLUMN_MIME_TYPE
                                                )

                                        while (cursor.moveToNext()) {
                                                val mime = cursor.getString(mimeIdx)
                                                if (mime == DocumentsContract.Document.MIME_TYPE_DIR) {
                                                        val name = cursor.getString(nameIdx) ?: ""
                                                        val docId = cursor.getString(idIdx)
                                                        if (name == targetName) {
                                                                return docId
                                                        }
                                                        if (depth < 5 &&
                                                                        intermediateDirs.any {
                                                                                it.equals(
                                                                                        name,
                                                                                        ignoreCase = true
                                                                                )
                                                                        }
                                                        ) {
                                                                queue.add(docId to depth + 1)
                                                        }
                                                }
                                        }
                                }
                }
                return null
        }

        private fun resolveDurationsParallel(
                items: List<Triple<Uri, Long, Long>>
        ): Map<String, Long> {
                if (items.isEmpty()) return emptyMap()

                val prefs =
                        applicationContext.getSharedPreferences(
                                "media_duration_cache",
                                Context.MODE_PRIVATE
                        )
                val results = ConcurrentHashMap<String, Long>(items.size)
                val uncached = mutableListOf<Triple<Uri, Long, Long>>()

                for (item in items) {
                        val key = "${item.first}|${item.second}|${item.third}"
                        val cached = prefs.getLong(key, -1L)
                        if (cached >= 0L) {
                                results[item.first.toString()] = cached
                        } else {
                                uncached.add(item)
                        }
                }

                if (uncached.isEmpty()) return results

                val workerCount = minOf(6, uncached.size)
                val chunkSize = (uncached.size + workerCount - 1) / workerCount
                val chunks = uncached.chunked(chunkSize)
                val executor = Executors.newFixedThreadPool(workerCount)
                val newEntries = ConcurrentHashMap<String, Long>(uncached.size)

                try {
                        val tasks =
                                chunks.map { chunk ->
                                        Callable {
                                                val retriever = MediaMetadataRetriever()
                                                try {
                                                        for ((uri, lastModified, size) in chunk) {
                                                                var durationMs = 0L
                                                                try {
                                                                        retriever.setDataSource(
                                                                                applicationContext,
                                                                                uri
                                                                        )
                                                                        val durationStr =
                                                                                retriever.extractMetadata(
                                                                                        MediaMetadataRetriever
                                                                                                .METADATA_KEY_DURATION
                                                                                )
                                                                        durationMs =
                                                                                durationStr
                                                                                        ?.toLongOrNull()
                                                                                        ?: 0L
                                                                } catch (_: Exception) {}
                                                                results[uri.toString()] = durationMs
                                                                newEntries["$uri|$lastModified|$size"] =
                                                                        durationMs
                                                        }
                                                } finally {
                                                        try {
                                                                retriever.release()
                                                        } catch (_: Exception) {}
                                                }
                                        }
                                }
                        executor.invokeAll(tasks)
                } finally {
                        executor.shutdown()
                }

                if (newEntries.isNotEmpty()) {
                        val editor = prefs.edit()
                        for ((k, v) in newEntries) {
                                editor.putLong(k, v)
                        }
                        editor.apply()
                }

                return results
        }
}
