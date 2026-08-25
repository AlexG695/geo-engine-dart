import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../app_device_integrity.dart';
import '../models/sdk_exceptions.dart';
import '../version.dart';

/// Coordinates device attestation and JWT session lifecycle with the GeoEngine backend.
class IntegrityAuthManager {
  /// Base URL of the management and authentication service.
  final String managementUrl;

  /// Google Cloud project number required for Android Play Integrity API.
  final String? androidCloudProjectNumber;

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  static const String _sessionJwtStorageKey = 'geoengine_session_jwt';
  static const String _ingestionJwtStorageKey = 'geoengine_ingestion_jwt';
  static const String _ingestionExpiryStorageKey =
      'geoengine_ingestion_jwt_expiry';

  /// Creates an instance of [IntegrityAuthManager].
  IntegrityAuthManager({
    required this.managementUrl,
    this.androidCloudProjectNumber,
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Persists the driver's session JWT obtained during primary authentication.
  Future<void> setSessionJwt(String sessionJwt) async {
    await _secureStorage.write(key: _sessionJwtStorageKey, value: sessionJwt);
    await _secureStorage.delete(key: _ingestionJwtStorageKey);
    await _secureStorage.delete(key: _ingestionExpiryStorageKey);
  }

  /// Retrieves a valid cached ingestion JWT or executes a device integrity challenge
  /// using the active session JWT.
  ///
  /// Forces a fresh challenge exchange if [forceRefresh] is set to `true`.
  Future<String> getOrRefreshIngestionJwt({
    required String deviceId,
    required String packageName,
    bool forceRefresh = false,
  }) async {
    final effectivePackageName =
        packageName.isEmpty ? 'dev.geoengine.app' : packageName;

    if (!forceRefresh) {
      final cachedIngestionJwt =
          await _secureStorage.read(key: _ingestionJwtStorageKey);
      final expiryStr =
          await _secureStorage.read(key: _ingestionExpiryStorageKey);

      if (cachedIngestionJwt != null && expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null &&
            DateTime.now()
                .isBefore(expiry.subtract(const Duration(minutes: 5)))) {
          return cachedIngestionJwt;
        }
      }
    }

    final sessionJwt = await _secureStorage.read(key: _sessionJwtStorageKey);
    if (sessionJwt == null || sessionJwt.isEmpty) {
      throw const IntegrityVerificationException(
        'Missing active session JWT. Driver must log in before location ingestion.',
        statusCode: 401,
      );
    }

    return _executeIntegrityChallenge(
      deviceId: deviceId,
      packageName: effectivePackageName,
      sessionJwt: sessionJwt,
    );
  }

  Future<String> _executeIntegrityChallenge({
    required String deviceId,
    required String packageName,
    required String sessionJwt,
  }) async {
    final challengeUri = Uri.parse('$managementUrl/api/v1/device/challenge');
    final deviceModel = await AppDeviceIntegrity.getDeviceModel();
    final deviceHash = await AppDeviceIntegrity.getNativeDeviceId();
    final model =
        deviceModel == null || deviceModel.isEmpty ? 'unknown' : deviceModel;

    final challengeResponse = await _httpClient.post(
      challengeUri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $sessionJwt',
      },
      body: jsonEncode({
        'hardware_fingerprint': deviceHash,
        'name': packageName,
        'os': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'model': model,
        'sdk_version': geoEngineSdkVersion,
      }),
    );

    if (challengeResponse.statusCode != 200) {
      throw IntegrityVerificationException(
        'Failed to obtain security challenge nonce: ${challengeResponse.body}',
        statusCode: challengeResponse.statusCode,
      );
    }

    final nonce = jsonDecode(challengeResponse.body)['nonce'] as String;
    final serverDeviceId =
        jsonDecode(challengeResponse.body)['device_id'] as String;

    final playToken = await AppDeviceIntegrity.generateIntegrityToken(
      cloudProjectNumber: androidCloudProjectNumber,
      nonce: nonce,
    );

    final verifyUri = Uri.parse('$managementUrl/api/v1/device/verify');
    final verifyResponse = await _httpClient.post(
      verifyUri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $sessionJwt',
        'X-Package-Name': packageName,
      },
      body: jsonEncode({'device_id': serverDeviceId, 'token': playToken}),
    );

    if (verifyResponse.statusCode != 200) {
      throw IntegrityVerificationException(
        'Device attestation failed: ${verifyResponse.body}',
        statusCode: verifyResponse.statusCode,
      );
    }

    final body = jsonDecode(verifyResponse.body) as Map<String, dynamic>;
    final ingestionJwt = body['jwt'] as String;
    final expiresIn = body['expires_in'] as int? ?? 25200;

    final expiryDate = DateTime.now().add(Duration(seconds: expiresIn));

    await _secureStorage.write(
        key: _ingestionJwtStorageKey, value: ingestionJwt);
    await _secureStorage.write(
        key: _ingestionExpiryStorageKey, value: expiryDate.toIso8601String());

    return ingestionJwt;
  }
}
