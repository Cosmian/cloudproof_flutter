import Flutter
import UIKit

public class SwiftCloudproofPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // let channel = FlutterMethodChannel(name: "cloudproof", binaryMessenger: registrar.messenger())
    // let instance = SwiftCloudproofPlugin()
    // registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
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
      nil,
      nil,
      nil
      );
  }


}
