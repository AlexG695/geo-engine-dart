import 'package:flutter/services.dart';

/// Handles the communication with native platform integrity services.
///
/// This class is responsible for requesting the integrity token from
/// Google Play Integrity (Android) or DeviceCheck (iOS) to validate
/// that the device is genuine and untampered.
class AppDeviceIntegrity {
  static const MethodChannel _channel = MethodChannel('app_device_integrity');

  /// Requests a new integrity token from the underlying platform.
  ///
  /// [nonce] is a unique challenge string from your backend to prevent replay attacks.
  /// [cloudProjectNumber] is required for Google Play Integrity (Android).
  ///
  /// Returns a Base64 encoded token string or throws an exception if
  /// the device is not supported.
  static Future<String?> generateIntegrityToken(
      {String? cloudProjectNumber}) async {
    try {
      final String? token =
          await _channel.invokeMethod('generateIntegrityToken', {
        'projectNumber': cloudProjectNumber,
      });
      return token;
    } on PlatformException catch (e) {
      print("Integrity Check Error: ${e.message}");
      return null;
    } catch (e) {
      print("Integrity Check Unknown Error: $e");
      return null;
    }
  }
}
