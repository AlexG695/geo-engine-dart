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

    } else if call.method == "getDeviceModel" {
      result(UIDevice.current.model)

    } else {
      result(FlutterMethodNotImplemented)
        }
    }

    public static func getOrCreateDeviceId() -> String {
        if let existingId = loadFromKeychain() {
            return existingId
        }

        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let modelCode = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        let rawSeed = "\(idfv):\(modelCode)"
        let generatedId = sha256(rawSeed)

        saveToKeychain(value: generatedId)

        return generatedId
    }

    private static func saveToKeychain(value: String) {
        if let data = value.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: accountName,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            SecItemDelete(query as CFDictionary)
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    private static func loadFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data, let result = String(data: data, encoding: .utf8) {
            return result
        }
        return nil
    }

    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        inputData.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(inputData.count), &digest)
        }
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
