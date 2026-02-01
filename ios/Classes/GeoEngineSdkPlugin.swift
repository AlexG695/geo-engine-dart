import Flutter
import UIKit
import DeviceCheck

public class GeoEngineSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
       let channel = FlutterMethodChannel(name: "app_device_integrity", binaryMessenger: registrar.messenger())
       let instance = GeoEngineSdkPlugin()
       registrar.addMethodCallDelegate(instance, channel: channel)
  }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "generateIntegrityToken" {
          if DCDevice.current.isSupported {

            DCDevice.current.generateToken { data, error in
              if let error = error {
                result(FlutterError(code: "IOS_INTEGRITY_ERROR", message: error.localizedDescription, details: nil))
                return
              }

              guard let data = data else {
                result(FlutterError(code: "IOS_INTEGRITY_ERROR", message: "Token data is null", details: nil))
                return
              }

              let tokenString = data.base64EncodedString()
              result(tokenString)
            }

          } else {
            result(FlutterError(code: "UNSUPPORTED_DEVICE", message: "DeviceCheck is not supported on this device (Simulator?)", details: nil))
          }

        } else {
          result(FlutterMethodNotImplemented)
        }
    }
}
