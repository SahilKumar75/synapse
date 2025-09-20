import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Google Maps API Key
    GMSServices.provideAPIKey("AIzaSyDSKfX62OR56G4BZnAVtr_FzcvoIwA9IZI")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
