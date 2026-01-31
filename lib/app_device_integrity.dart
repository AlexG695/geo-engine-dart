import 'package:flutter/services.dart';

class AppDeviceIntegrity {
  static const MethodChannel _channel = MethodChannel('app_device_integrity');

  static Future<String?> generateIntegrityToken({String? cloudProjectNumber}) async {
    try {
      final String? token = await _channel.invokeMethod('generateIntegrityToken', {
        'cloudProjectNumber': cloudProjectNumber,
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