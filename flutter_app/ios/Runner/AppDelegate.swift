import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "ps.tradex.app/whatsapp_support",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "open",
              let arguments = call.arguments as? [String: Any],
              let urlString = arguments["url"] as? String,
              let url = URL(string: urlString) else {
          result(false)
          return
        }

        UIApplication.shared.open(url, options: [:]) { opened in
          result(opened)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
