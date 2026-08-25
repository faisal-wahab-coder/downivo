package com.pm.downivo

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
}
