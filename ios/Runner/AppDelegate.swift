import UIKit
import Flutter
import google_mobile_ads

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let factory = ShoqlistNativeAdFactory()
    let registered = FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
        self, factoryId: "shoqlistNativeAd", nativeAdFactory: factory)
    NSLog("[AppDelegate] registerNativeAdFactory registered=\(registered)")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
