import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:geo_engine_sdk/geo_engine_sdk.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MockPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '.';
  }

  @override
  Future<String?> getTemporaryPath() async {
    return '.';
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    PathProviderPlatform.instance = MockPathProvider();

    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);

    const MethodChannel('dev.fluttercommunity.plus/connectivity')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'check') {
        return ['wifi'];
      }
      return null;
    });
    const MethodChannel('app_device_integrity')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'generateIntegrityToken') {
        return "token_de_prueba_simulado_12345";
      }
      return null;
    });
  });

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Geo Test',
      packageName: 'com.alexg.geo_lab',
      version: '1.0',
      buildNumber: '1',
      buildSignature: '',
    );

    GeoEngine.debugSimulateAndroid = true;
  });

  tearDown(() async {
    GeoEngine.debugSimulateAndroid = null;
    await Hive.deleteFromDisk();
  });

  setUp(() async {
    if (!Hive.isBoxOpen('geo_engine_buffer')) {
      await Hive.openBox('geo_engine_buffer');
    }
    await Hive.box('geo_engine_buffer').clear();
    HttpOverrides.global = null;
  });

  MockClient createGoBackendMock() {
    return MockClient((request) async {
      final url = request.url.toString();

      if (url.contains('/api/v1/device/challenge')) {
        return http.Response('{"nonce": "mock_nonce_123"}', 200);
      } else if (url.contains('/api/v1/device/verify')) {
        final body = jsonDecode(request.body);
        if (body['play_token'] == "token_de_prueba_simulado_12345" ||
            body['token'] == "token_de_prueba_simulado_12345") {
          return http.Response(
              '{"status": "verified", "jwt": "mock_jwt_token_999"}', 200);
        }
        print('MOCK ERROR (Verify): El token no coincide. Body enviado: $body');
        return http.Response('Integrity failed', 403);
      } else if (url.contains('/v1/ingest/batch')) {
        final authHeader = request.headers['Authorization'];
        final legacyHeader = request.headers['X-Device-Integrity'];

        if (authHeader == "Bearer mock_jwt_token_999" ||
            legacyHeader == "mock_jwt_token_999" ||
            legacyHeader == "Bearer mock_jwt_token_999") {
          return http.Response('{"status": "success"}', 200);
        } else {
          print(
              'MOCK ERROR (Ingest): Falta el JWT en los Headers. Headers enviados: ${request.headers}');
          return http.Response('Unauthorized', 401);
        }
      }
      return http.Response('Not Found', 404);
    });
  }

  MockClient createOfflineMock() {
    return MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });
  }

  group('GeoEngine SDK Tests', () {
    test(
        'sendLocation debería guardar los datos en Hive (Buffer) cuando no hay red',
        () async {
      final geo = GeoEngine(apiKey: 'test-key', client: createOfflineMock());
      await geo.sendLocation(
          deviceId: 'device-test-01', latitude: 10.0, longitude: 20.0);

      Box box = Hive.isBoxOpen('geo_engine_buffer')
          ? Hive.box('geo_engine_buffer')
          : await Hive.openBox('geo_engine_buffer');

      expect(box.length, 1);
    });

    test('El SDK debería acumular múltiples pings en el buffer', () async {
      final geo = GeoEngine(apiKey: 'test-key', client: createOfflineMock());
      await geo.sendLocation(deviceId: 'd1', latitude: 10, longitude: 10);
      await geo.sendLocation(deviceId: 'd1', latitude: 11, longitude: 11);
      await geo.sendLocation(deviceId: 'd1', latitude: 12, longitude: 12);

      Box box = Hive.isBoxOpen('geo_engine_buffer')
          ? Hive.box('geo_engine_buffer')
          : await Hive.openBox('geo_engine_buffer');

      expect(box.length, 3);
    });

    test('El SDK debería ejecutar el Handshake, obtener JWT y vaciar el buffer',
        () async {
      final geo = GeoEngine(apiKey: 'test-key', client: createGoBackendMock());
      await geo.sendLocation(
          deviceId: 'device-success', latitude: 40.0, longitude: -3.0);

      await Future.delayed(const Duration(milliseconds: 500));

      Box box = Hive.isBoxOpen('geo_engine_buffer')
          ? Hive.box('geo_engine_buffer')
          : await Hive.openBox('geo_engine_buffer');

      expect(box.length, 0,
          reason: 'El buffer no se vació. Revisa los prints en consola.');
    });

    test(
        'El SDK debería incluir el header Authorization: Bearer al enviar datos',
        () async {
      final geo = GeoEngine(
        apiKey: 'test-key',
        androidCloudProjectNumber: '123456',
        client: createGoBackendMock(),
      );

      await geo.sendLocation(
          deviceId: 'device-secure', latitude: 50.0, longitude: 50.0);

      await Future.delayed(const Duration(milliseconds: 500));

      Box box = Hive.isBoxOpen('geo_engine_buffer')
          ? Hive.box('geo_engine_buffer')
          : await Hive.openBox('geo_engine_buffer');

      expect(box.length, 0,
          reason:
              'El servidor rechazó el envío. Revisa los prints de los headers.');
    });
  });

  tearDownAll(() async {
    try {
      await Hive.close();
      await Hive.deleteFromDisk();
    } catch (e) {}
  });
}
