package edu.ynu.isc.roll_call_app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// 接收系统"用其他应用打开"传入的文档（与 iOS DocumentImportPlugin 同协议）。
// 冷启动先复制到缓存并缓存路径，待 Dart 调 getPendingDocuments 时同步返回；
// 运行中收到新文档直接推送。与 iOS 版语义一致：getPendingDocuments 同步返回路径数组。
// 微信/QQ 传入的是 content:// Uri 且多数只授予一次性读权限，
// 立即复制到私有缓存目录再传路径给 Dart，避免读完即失效。
class MainActivity : FlutterActivity() {
  private val channelName = "edu.ynu.isc.rollCallApp/documents"
  private var channel: MethodChannel? = null
  private var channelReady = false
  private var pendingPaths = mutableListOf<String>()

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .also { ch ->
        ch.setMethodCallHandler { call, result ->
          when (call.method) {
            "getPendingDocuments" -> {
              channelReady = true
              val paths = ArrayList(pendingPaths)
              pendingPaths.clear()
              result.success(paths)
            }
            else -> result.notImplemented()
          }
        }
      }
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    handleViewIntent(intent)
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    handleViewIntent(intent)
  }

  private fun handleViewIntent(intent: Intent?) {
    if (intent?.action != Intent.ACTION_VIEW) return
    val uri = intent.data ?: return
    Thread {
      val path = copyToCache(uri)
      if (path == null) return@Thread
      runOnUiThread {
        if (channelReady) {
          channel?.invokeMethod("documentReceived", listOf(path))
        } else {
          pendingPaths.add(path)
        }
      }
    }.start()
  }

  // content:// Uri 复制到缓存目录；file:// 直接用路径。
  private fun copyToCache(uri: Uri): String? {
    return try {
      if (uri.scheme == "file") return uri.path
      val input = contentResolver.openInputStream(uri) ?: return null
      val suffix = if (contentResolver.getType(uri)?.contains("sheet") == true) ".xlsx" else ".tmp"
      val out = java.io.File(cacheDir, "import_${System.currentTimeMillis()}$suffix")
      input.use { src -> out.outputStream().use { dst -> src.copyTo(dst) } }
      out.absolutePath
    } catch (e: Exception) {
      android.util.Log.e("DocumentImport", "copy failed: ${e.message}")
      null
    }
  }
}
