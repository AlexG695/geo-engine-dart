import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../app_device_integrity.dart';
import '../models/sdk_exceptions.dart';
import '../version.dart';
import 'zero_trust_auth_client.dart';

/// Coordinates device attestation and JWT lifecycle with the GeoEngine backend.
///
/// Implements [TokenProvider] to support Zero Trust machine-to-machine (M2M)
/// assertion flows without requiring an interactive user login.
class IntegrityAuthManager implements TokenProvider {
  /// The base URL of the management and authentication service.
  final String managementUrl;

  /// The Google Cloud project number required for Android Play Integrity checks.
  final String? androidCloudProjectNumber;

  /// The machine or client identifier.
  final String clientId;

  /// The device shared secret used for HMAC proof-of-possession signing.
  final String deviceSecret;

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;

  String? _inMemoryJwt;
  DateTime? _inMemoryExpiry;
  Completer<String>? _ongoingChallengeCompleter;

  static const String _sessionJwtStorageKey = 'geoengine_session_jwt';
  static const String _ingestionJwtStorageKey = 'geoengine_ingestion_jwt';
  static const String _ingestionExpiryStorageKey =
      'geoengine_ingestion_jwt_expiry';

  /// Creates an instance of [IntegrityAuthManager].
  IntegrityAuthManager({
    required this.managementUrl,
    this.clientId = '',
    this.deviceSecret = '',
    this.androidCloudProjectNumber,
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Persists an optional user session JWT for hybrid driver flows.
  Future<void> setSessionJwt(String sessionJwt) async {
    await _secureStorage.write(key: _sessionJwtStorageKey, value: sessionJwt);
    invalidateToken();
  }

  @override
  void invalidateToken() {
    _inMemoryJwt = null;
    _inMemoryExpiry = null;
    _secureStorage.delete(key: _ingestionJwtStorageKey);
    _secureStorage.delete(key: _ingestionExpiryStorageKey);
  }

  @override
  Future<String> getValidToken({
    bool forceRefresh = false,
    String? deviceId,
    String? packageName,
  }) async {
    if (!forceRefresh && _inMemoryJwt != null && _inMemoryExpiry != null) {
      if (DateTime.now()
          .isBefore(_inMemoryExpiry!.subtract(const Duration(minutes: 5)))) {
        return _inMemoryJwt!;
      }
    }

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
          _inMemoryJwt = cachedIngestionJwt;
          _inMemoryExpiry = expiry;
          return cachedIngestionJwt;
        }
      }
    }

    if (_ongoingChallengeCompleter != null) {
      return _ongoingChallengeCompleter!.future;
    }

    final completer = Completer<String>();
    _ongoingChallengeCompleter = completer;

    try {
      final jwt = await _executeM2MAssertion(
        deviceId: deviceId,
        packageName: packageName,
      );
      completer.complete(jwt);
      return jwt;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _ongoingChallengeCompleter = null;
    }
  }

  /// Retrieves a valid ingestion JWT, refreshing it if expired.
  Future<String> getOrRefreshIngestionJwt({
    required String deviceId,
    required String packageName,
    bool forceRefresh = false,
  }) {
    return getValidToken(
      forceRefresh: forceRefresh,
      deviceId: deviceId,
      packageName: packageName,
    );
  }

  Future<String> _executeM2MAssertion({
    String? deviceId,
    String? packageName,
  }) async {
    final effectivePackageName = (packageName != null && packageName.isNotEmpty)
        ? packageName
        : 'dev.geoengine.app';

    final effectiveDeviceId = (deviceId != null && deviceId.isNotEmpty)
        ? deviceId
        : (clientId.isNotEmpty
            ? clientId
            : await AppDeviceIntegrity.getNativeDeviceId());

    final deviceModel = await AppDeviceIntegrity.getDeviceModel();
    final deviceHash = await AppDeviceIntegrity.getNativeDeviceId();
    final model =
        deviceModel == null || deviceModel.isEmpty ? 'unknown' : deviceModel;

    final sessionJwt = await _secureStorage.read(key: _sessionJwtStorageKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    final challengeHeaders = <String, String>{
      'Content-Type': 'application/json',
      'X-Client-ID': effectiveDeviceId,
      'X-Request-Time': now.toString(),
    };

    if (deviceSecret.isNotEmpty) {
      challengeHeaders['X-Signature'] =
          ZeroTrustAuthClient.generateHmacSignature(
        secret: deviceSecret,
        clientId: effectiveDeviceId,
        timestampMs: now,
        path: '/api/v1/device/challenge',
      );
    }

    if (sessionJwt != null && sessionJwt.isNotEmpty) {
      challengeHeaders['Authorization'] = 'Bearer $sessionJwt';
    }

    final challengeBody = jsonEncode({
      'client_id': effectiveDeviceId,
      'hardware_fingerprint': deviceHash,
      'name': effectivePackageName,
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'model': model,
      'sdk_version': geoEngineSdkVersion,
    });

    var challengeUri = Uri.parse('$managementUrl/api/v1/device/challenge');
    var challengeResponse = await _httpClient.post(
      challengeUri,
      headers: challengeHeaders,
      body: challengeBody,
    );

    if (challengeResponse.statusCode == 404) {
      challengeUri = Uri.parse('$managementUrl/api/devices/challenge');
      challengeResponse = await _httpClient.post(
        challengeUri,
        headers: challengeHeaders,
        body: challengeBody,
      );
    }

    if (challengeResponse.statusCode != 200) {
      throw IntegrityVerificationException(
        'Failed to obtain security challenge nonce: ${challengeResponse.body}',
        statusCode: challengeResponse.statusCode,
      );
    }

    final challengeData =
        jsonDecode(challengeResponse.body) as Map<String, dynamic>;
    final dataMap = challengeData['data'] is Map<String, dynamic>
        ? challengeData['data'] as Map<String, dynamic>
        : challengeData;

    final nonce = dataMap['nonce'] as String;
    final serverDeviceId =
        (dataMap['device_id'] as String?) ?? effectiveDeviceId;

    final playToken = await AppDeviceIntegrity.generateIntegrityToken(
      cloudProjectNumber: androidCloudProjectNumber,
      nonce: nonce,
    );

    final verifyNow = DateTime.now().millisecondsSinceEpoch;
    final verifyHeaders = <String, String>{
      'Content-Type': 'application/json',
      'X-Client-ID': effectiveDeviceId,
      'X-Package-Name': effectivePackageName,
      'X-Request-Time': verifyNow.toString(),
    };

    if (deviceSecret.isNotEmpty) {
      verifyHeaders['X-Signature'] = ZeroTrustAuthClient.generateHmacSignature(
        secret: deviceSecret,
        clientId: effectiveDeviceId,
        timestampMs: verifyNow,
        path: '/api/v1/device/verify',
      );
    }

    if (sessionJwt != null && sessionJwt.isNotEmpty) {
      verifyHeaders['Authorization'] = 'Bearer $sessionJwt';
    }

    final verifyBody = jsonEncode({
      'device_id': serverDeviceId,
      'client_id': effectiveDeviceId,
      'token': playToken,
      'nonce': nonce,
    });

    var verifyUri = Uri.parse('$managementUrl/api/v1/device/verify');
    var verifyResponse = await _httpClient.post(
      verifyUri,
      headers: verifyHeaders,
      body: verifyBody,
    );

    if (verifyResponse.statusCode == 404) {
      verifyUri = Uri.parse('$managementUrl/api/devices/verify');
      verifyResponse = await _httpClient.post(
        verifyUri,
        headers: verifyHeaders,
        body: verifyBody,
      );
    }

    if (verifyResponse.statusCode != 200) {
      throw IntegrityVerificationException(
        'Device attestation failed: ${verifyResponse.body}',
        statusCode: verifyResponse.statusCode,
      );
    }

    final body = jsonDecode(verifyResponse.body) as Map<String, dynamic>;
    final verifyData = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;

    final ingestionJwt = (verifyData['jwt'] ?? body['jwt']) as String;
    final expiresIn =
        (verifyData['expires_in'] ?? body['expires_in'] ?? 3600) as int;

    final expiryDate = DateTime.now().add(Duration(seconds: expiresIn));

    _inMemoryJwt = ingestionJwt;
    _inMemoryExpiry = expiryDate;

    await _secureStorage.write(
      key: _ingestionJwtStorageKey,
      value: ingestionJwt,
    );
    await _secureStorage.write(
      key: _ingestionExpiryStorageKey,
      value: expiryDate.toIso8601String(),
    );

    return ingestionJwt;
  }
}
