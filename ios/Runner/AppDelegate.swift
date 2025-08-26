import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyA5d1fDP_IpTBJtbzMPKfWNup9SxcegOQY")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
