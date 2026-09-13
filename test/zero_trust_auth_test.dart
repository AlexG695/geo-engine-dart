import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_engine_sdk/geo_engine_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockTokenProvider implements TokenProvider {
  int fetchCount = 0;
  int invalidateCount = 0;
  String currentToken = 'token_v1';

  @override
  Future<String> getValidToken({bool forceRefresh = false}) async {
    fetchCount++;
    if (forceRefresh) {
      currentToken = 'token_v2_refreshed';
    }
    return currentToken;
  }

  @override
  void invalidateToken() {
    invalidateCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('app_device_integrity'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'generateIntegrityToken':
            return 'mock_integrity_token_abc';
          case 'getDeviceModel':
            return 'MockPhone M2M';
          case 'getNativeDeviceId':
            return 'm2m_device_99';
          default:
            return null;
        }
      },
    );
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('ZeroTrustAuthClient', () {
    test('Injects M2M headers, Bearer token, and valid HMAC-SHA256 signature',
        () async {
      final tokenProvider = MockTokenProvider();
      const clientId = 'device_test_123';
      const deviceSecret = 'super_secret_hmac_key_999';

      late http.Request capturedRequest;

      final mockInner = MockClient((http.Request req) async {
        capturedRequest = req;
        return http.Response('{"status":"ok"}', 200);
      });

      final client = ZeroTrustAuthClient(
        tokenProvider: tokenProvider,
        clientId: clientId,
        deviceSecret: deviceSecret,
        environment: 'staging',
        innerClient: mockInner,
      );

      final response = await client.post(
        Uri.parse('https://api.geoengine.dev/v1/ping'),
        body: jsonEncode({'lat': 10.0, 'lng': -20.0}),
      );

      expect(response.statusCode, 200);
      expect(capturedRequest.headers['Authorization'], 'Bearer token_v1');
      expect(capturedRequest.headers['X-Client-ID'], clientId);
      expect(capturedRequest.headers['X-Geo-Environment'], 'staging');
      expect(capturedRequest.headers['X-Request-Time'], isNotNull);

      // Verify HMAC-SHA256 signature
      final timestamp = int.parse(capturedRequest.headers['X-Request-Time']!);
      final expectedSig = ZeroTrustAuthClient.generateHmacSignature(
        secret: deviceSecret,
        clientId: clientId,
        timestampMs: timestamp,
        path: '/v1/ping',
      );
      expect(capturedRequest.headers['X-Signature'], expectedSig);
    });

    test('Transparently retries on HTTP 401 with fresh token', () async {
      final tokenProvider = MockTokenProvider();
      int requestAttempts = 0;
      final capturedTokens = <String>[];

      final mockInner = MockClient((http.Request req) async {
        requestAttempts++;
        capturedTokens.add(req.headers['Authorization']!);

        if (requestAttempts == 1) {
          return http.Response('Unauthorized', 401);
        }
        return http.Response('{"status":"success_after_refresh"}', 200);
      });

      final client = ZeroTrustAuthClient(
        tokenProvider: tokenProvider,
        clientId: 'device_retry_test',
        deviceSecret: 'secret_key',
        innerClient: mockInner,
      );

      final response = await client.post(
        Uri.parse('https://api.geoengine.dev/v1/telemetry'),
        body: 'test_payload',
      );

      expect(response.statusCode, 200);
      expect(response.body, contains('success_after_refresh'));
      expect(requestAttempts, 2);
      expect(tokenProvider.invalidateCount, 1);
      expect(tokenProvider.fetchCount, 2);
      expect(capturedTokens, ['Bearer token_v1', 'Bearer token_v2_refreshed']);
    });
  });

  group('IntegrityAuthManager Zero Trust M2M', () {
    test('Executes M2M assertion without human sessionJwt', () async {
      int challengeCalls = 0;
      int verifyCalls = 0;

      final mockHttpClient = MockClient((http.Request req) async {
        final url = req.url.toString();
        if (url.contains('/device/challenge')) {
          challengeCalls++;
          expect(req.headers['X-Client-ID'], 'm2m_device_99');
          expect(req.headers['X-Signature'], isNotEmpty);
          return http.Response(
            jsonEncode({
              'nonce': 'nonce_m2m_abc',
              'device_id': 'm2m_device_99',
            }),
            200,
          );
        }
        if (url.contains('/device/verify')) {
          verifyCalls++;
          expect(req.headers['X-Client-ID'], 'm2m_device_99');
          return http.Response(
            jsonEncode({
              'jwt': 'jwt_m2m_scoped_token_xyz',
              'expires_in': 3600,
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final authManager = IntegrityAuthManager(
        managementUrl: 'https://management.geoengine.dev',
        clientId: 'm2m_device_99',
        deviceSecret: 'device_secret_abc',
        httpClient: mockHttpClient,
      );

      // Call 1: Fetches via M2M assertion
      final token1 = await authManager.getValidToken(deviceId: 'm2m_device_99');
      expect(token1, 'jwt_m2m_scoped_token_xyz');
      expect(challengeCalls, 1);
      expect(verifyCalls, 1);

      // Call 2: Must be served from L1 memory cache without HTTP calls
      final token2 = await authManager.getValidToken(deviceId: 'm2m_device_99');
      expect(token2, 'jwt_m2m_scoped_token_xyz');
      expect(challengeCalls, 1,
          reason: 'L1 cache must prevent second HTTP challenge call');
      expect(verifyCalls, 1,
          reason: 'L1 cache must prevent second HTTP verify call');
    });

    test(
        'Thundering herd protection joins concurrent token requests into a single network call',
        () async {
      int challengeCalls = 0;

      final mockHttpClient = MockClient((http.Request req) async {
        final url = req.url.toString();
        if (url.contains('/device/challenge')) {
          challengeCalls++;
          // Simulate latency
          await Future.delayed(const Duration(milliseconds: 50));
          return http.Response(
            jsonEncode({
              'nonce': 'nonce_concurrent',
              'device_id': 'device_concurrent_1',
            }),
            200,
          );
        }
        if (url.contains('/device/verify')) {
          await Future.delayed(const Duration(milliseconds: 50));
          return http.Response(
            jsonEncode({
              'jwt': 'jwt_concurrent_valid',
              'expires_in': 3600,
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final authManager = IntegrityAuthManager(
        managementUrl: 'https://management.geoengine.dev',
        clientId: 'device_concurrent_1',
        deviceSecret: 'secret_concurrent',
        httpClient: mockHttpClient,
      );

      // Trigger 10 concurrent requests simultaneously
      final futures = List.generate(
        10,
        (_) => authManager.getValidToken(deviceId: 'device_concurrent_1'),
      );

      final results = await Future.wait(futures);

      // All 10 callers must receive the exact same token
      for (final res in results) {
        expect(res, 'jwt_concurrent_valid');
      }

      // Must have executed only 1 challenge exchange across all 10 callers
      expect(challengeCalls, 1);
    });
  });
}
