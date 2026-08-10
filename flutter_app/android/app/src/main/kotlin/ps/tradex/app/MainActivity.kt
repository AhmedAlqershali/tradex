package ps.tradex.app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ps.tradex.app/whatsapp_support",
        ).setMethodCallHandler { call, result ->
            if (call.method != "open") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val url = call.argument<String>("url")
            if (url == null) {
                result.success(false)
                return@setMethodCallHandler
            }

            try {
                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                result.success(true)
            } catch (_: Exception) {
                result.success(false)
            }
        }
    }
}
