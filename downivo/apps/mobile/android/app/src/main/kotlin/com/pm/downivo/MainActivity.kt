package com.pm.downivo

import android.content.ClipData
import android.content.Intent
import android.os.StatFs
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.downivo.files/open",
        ).setMethodCallHandler { call, result ->
            if (call.method == "openWith") {
                val path = call.argument<String>("path")
                val mime = call.argument<String>("mime")
                if (path.isNullOrBlank()) {
                    result.success(
                        mapOf("success" to false, "message" to "File not found."),
                    )
                    return@setMethodCallHandler
                }
                openWithChooser(path, mime, result)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.downivo.storage/disk",
        ).setMethodCallHandler { call, result ->
            if (call.method == "volumeStats") {
                val path = call.argument<String>("path") ?: filesDir.absolutePath
                try {
                    File(path).mkdirs()
                    val stat = StatFs(path)
                    result.success(
                        mapOf(
                            "freeBytes" to stat.availableBytes,
                            "totalBytes" to stat.totalBytes,
                        ),
                    )
                } catch (error: Exception) {
                    result.error("stat_failed", error.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openWithChooser(
        path: String,
        mime: String?,
        result: MethodChannel.Result,
    ) {
        val file = File(path)
        if (!file.exists()) {
            result.success(mapOf("success" to false, "message" to "File not found."))
            return
        }
        try {
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file,
            )
            val type = mime?.takeIf { it.isNotBlank() }
                ?: MimeTypeMap.getSingleton()
                    .getMimeTypeFromExtension(file.extension.lowercase())
                ?: "*/*"
            val view = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, type)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                clipData = ClipData.newRawUri("", uri)
            }
            val chooser = Intent.createChooser(view, "Open with").apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                clipData = ClipData.newRawUri("", uri)
            }
            if (view.resolveActivity(packageManager) == null) {
                result.success(
                    mapOf(
                        "success" to false,
                        "message" to "No app can open this file.",
                    ),
                )
                return
            }
            startActivity(chooser)
            result.success(mapOf("success" to true, "message" to ""))
        } catch (error: Exception) {
            result.success(
                mapOf(
                    "success" to false,
                    "message" to (error.message ?: "Could not open this file."),
                ),
            )
        }
    }
}
