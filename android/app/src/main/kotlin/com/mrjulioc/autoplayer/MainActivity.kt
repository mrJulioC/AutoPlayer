package com.mrjulioc.autoplayer

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.IntentSender
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.mrjulioc.autoplayer/media_store"

    private var pendingDeleteResult: MethodChannel.Result? = null

    companion object {
        private const val DELETE_REQUEST_CODE = 9001
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: android.content.Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == DELETE_REQUEST_CODE) {
            pendingDeleteResult?.success(resultCode == Activity.RESULT_OK)
            pendingDeleteResult = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "queryMedia" -> {
                    try {
                        result.success(queryMusicFolder())
                    } catch (error: SecurityException) {
                        result.error("PERMISSION_DENIED", error.message, null)
                    } catch (error: Exception) {
                        result.error("MEDIA_QUERY_FAILED", error.message, null)
                    }
                }

                "deleteMedia" -> {
                    val uriText = call.argument<String>("uri").orEmpty()

                    if (uriText.isBlank()) {
                        result.error("INVALID_URI", "URI vacía", null)
                        return@setMethodCallHandler
                    }

                    deleteMedia(Uri.parse(uriText), result)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun queryMusicFolder(): List<Map<String, Any?>> {
        val collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

        val pathColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Audio.Media.RELATIVE_PATH
        } else {
            @Suppress("DEPRECATION")
            MediaStore.Audio.Media.DATA
        }

        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.MIME_TYPE,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            pathColumn
        )

        val output = mutableListOf<Map<String, Any?>>()
        val seenUris = mutableSetOf<String>()

        contentResolver.query(
            collection,
            projection,
            null,
            null,
            "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val folder = cursor.stringValue(pathColumn).orEmpty()

                if (!isMusicFolder(folder)) {
                    continue
                }

                val id = cursor.longValue(MediaStore.Audio.Media._ID) ?: continue
                val uri = ContentUris.withAppendedId(collection, id).toString()

                if (!seenUris.add(uri)) {
                    continue
                }

                output.add(
                    mapOf(
                        "id" to id,
                        "uri" to uri,
                        "displayName" to cursor.stringValue(
                            MediaStore.Audio.Media.DISPLAY_NAME
                        ),
                        "title" to cursor.stringValue(
                            MediaStore.Audio.Media.TITLE
                        ),
                        "mimeType" to cursor.stringValue(
                            MediaStore.Audio.Media.MIME_TYPE
                        ),
                        "size" to cursor.longValue(
                            MediaStore.Audio.Media.SIZE
                        ),
                        "duration" to cursor.longValue(
                            MediaStore.Audio.Media.DURATION
                        ),
                        "artist" to cursor.stringValue(
                            MediaStore.Audio.Media.ARTIST
                        ),
                        "album" to cursor.stringValue(
                            MediaStore.Audio.Media.ALBUM
                        ),
                        "relativePath" to folder
                    )
                )
            }
        }

        return output.sortedBy {
            (it["title"] as? String ?: it["displayName"] as? String ?: "")
                .lowercase()
        }
    }

    private fun isMusicFolder(path: String): Boolean {
        val normalized = path
            .replace('\\', '/')
            .trim()
            .trimStart('/')
            .lowercase()

        return normalized == "music" ||
            normalized == "music/" ||
            normalized.startsWith("music/") ||
            normalized == "música" ||
            normalized == "música/" ||
            normalized.startsWith("música/")
    }

    private fun deleteMedia(uri: Uri, result: MethodChannel.Result) {
        if (pendingDeleteResult != null) {
            result.error(
                "DELETE_IN_PROGRESS",
                "Ya existe una eliminación pendiente",
                null
            )
            return
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val pendingIntent = MediaStore.createDeleteRequest(
                    contentResolver,
                    listOf(uri)
                )

                pendingDeleteResult = result
                launchDeleteConfirmation(pendingIntent.intentSender)
                return
            }

            val deleted = contentResolver.delete(uri, null, null) > 0
            result.success(deleted)
        } catch (error: RecoverableSecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                pendingDeleteResult = result
                launchDeleteConfirmation(
                    error.userAction.actionIntent.intentSender
                )
            } else {
                result.error("DELETE_FAILED", error.message, null)
            }
        } catch (error: SecurityException) {
            result.error("PERMISSION_DENIED", error.message, null)
        } catch (error: Exception) {
            result.error("DELETE_FAILED", error.message, null)
        }
    }

    private fun launchDeleteConfirmation(intentSender: IntentSender) {
        try {
            startIntentSenderForResult(
                intentSender,
                DELETE_REQUEST_CODE,
                null,
                0,
                0,
                0
            )
        } catch (error: IntentSender.SendIntentException) {
            pendingDeleteResult?.error(
                "DELETE_FAILED",
                error.message,
                null
            )
            pendingDeleteResult = null
        }
    }

    private fun Cursor.stringValue(column: String): String? {
        val index = getColumnIndex(column)
        return if (index >= 0 && !isNull(index)) getString(index) else null
    }

    private fun Cursor.longValue(column: String): Long? {
        val index = getColumnIndex(column)
        return if (index >= 0 && !isNull(index)) getLong(index) else null
    }
}
