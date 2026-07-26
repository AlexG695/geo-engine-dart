import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../app_device_integrity.dart';
import '../models/sdk_exceptions.dart';

/// Coordinates device attestation and JWT session lifecycle with the GeoEngine backend.
class IntegrityAuthManager {
  /// Base URL of the management and authentication service.
  final String managementUrl;

  /// Project API key issued in the GeoEngine dashboard.
  final String apiKey;

  /// Google Cloud project number required for Android Play Integrity API.
  final String? androidCloudProjectNumber;

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  static const String _jwtStorageKey = 'geoengine_device_jwt';
  static const String _expiryStorageKey = 'geoengine_jwt_expiry';

  /// Creates an instance of [IntegrityAuthManager].
  IntegrityAuthManager({
    required this.managementUrl,
    required this.apiKey,
    this.androidCloudProjectNumber,
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Retrieves a valid cached session JWT or executes a new device integrity challenge.
  ///
  /// Forces a fresh challenge exchange if [forceRefresh] is set to `true`.
  Future<String> getOrRefreshSessionJwt({
    required String deviceId,
    required String packageName,
    bool forceRefresh = false,
  }) async {
    final effectivePackageName =
        packageName.isEmpty ? 'dev.geoengine.app' : packageName;

    if (!forceRefresh) {
      final cachedJwt = await _secureStorage.read(key: _jwtStorageKey);
      final expiryStr = await _secureStorage.read(key: _expiryStorageKey);

      if (cachedJwt != null && expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null &&
            DateTime.now()
                .isBefore(expiry.subtract(const Duration(minutes: 5)))) {
          return cachedJwt;
        }
      }
    }

    return _executeIntegrityChallenge(
      deviceId: deviceId,
      packageName: effectivePackageName,
    );
  }

  Future<String> _executeIntegrityChallenge({
    required String deviceId,
    required String packageName,
  }) async {
    final challengeUri = Uri.parse('$managementUrl/api/v1/device/challenge');
    final challengeResponse = await _httpClient.post(
      challengeUri,
      headers: {'Content-Type': 'application/json', 'X-API-Key': apiKey},
      body: jsonEncode({'device_id': deviceId}),
    );

    if (challengeResponse.statusCode != 200) {
      throw IntegrityVerificationException(
        'Failed to obtain security challenge nonce: ${challengeResponse.body}',
        statusCode: challengeResponse.statusCode,
      );
    }

    final nonce = jsonDecode(challengeResponse.body)['nonce'] as String;

    final playToken = await AppDeviceIntegrity.generateIntegrityToken(
      cloudProjectNumber: androidCloudProjectNumber,
      nonce: nonce,
    );

    final verifyUri = Uri.parse('$managementUrl/api/v1/device/verify');
    final verifyResponse = await _httpClient.post(
      verifyUri,
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
        'X-Package-Name': packageName,
      },
      body: jsonEncode({
        'device_id': deviceId,
        'token': playToken,
        'play_token': playToken,
      }),
    );

    if (verifyResponse.statusCode != 200) {
      throw IntegrityVerificationException(
        'Device attestation failed: ${verifyResponse.body}',
        statusCode: verifyResponse.statusCode,
      );
    }

    final body = jsonDecode(verifyResponse.body) as Map<String, dynamic>;
    final jwt = body['jwt'] as String;
    final expiresIn = body['expires_in'] as int? ?? 25200;

    final expiryDate = DateTime.now().add(Duration(seconds: expiresIn));

    await _secureStorage.write(key: _jwtStorageKey, value: jwt);
    await _secureStorage.write(
        key: _expiryStorageKey, value: expiryDate.toIso8601String());

    return jwt;
  }
}
