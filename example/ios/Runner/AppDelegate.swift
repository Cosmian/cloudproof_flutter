import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    dummyMethodToEnforceCoverCryptBundling();
    dummyMethodToEnforceFindexBundling();

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  public func dummyMethodToEnforceCoverCryptBundling() {
    // This will never be executed :PreventTreeShaking
    h_aes_symmetric_encryption_overhead();
  }

  public func dummyMethodToEnforceFindexBundling() {
    // This will never be executed :PreventTreeShaking
    h_search(
      nil,
      nil,
      nil,
      0,
      nil,
      0,
      nil,
      0,
      0,
      0,
      0,
      nil,
      nil,
      nil
      );
  }

}
