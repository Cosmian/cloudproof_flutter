import Flutter
import UIKit

public class SwiftCloudproofPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cloudproof", binaryMessenger: registrar.messenger())
    let instance = SwiftCloudproofPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }

  public func dummyMethodToEnforceCoverCryptBundling() {
    // This will never be executed :PreventTreeShaking
    h_symmetric_encryption_overhead();
    h_generate_master_keys(nil,nil,nil,nil,nil,0);
    h_policy(nil,nil,0);
  }

  public func dummyMethodToEnforceFindexBundling() {
    // This will never be executed :PreventTreeShaking
    get_last_error(
      nil,
      nil
      );
  }
}
