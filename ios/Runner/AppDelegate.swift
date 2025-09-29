import Flutter
import UIKit
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String, !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }
    // Ensure APNs delegate and registration (FirebaseMessaging will hook via AppDelegate proxy)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    DispatchQueue.main.async {
      UIApplication.shared.registerForRemoteNotifications()
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
