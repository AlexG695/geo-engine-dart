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

  group('GeoEngine SDK Tests', () {
    test('sendLocation debería guardar los datos en Hive (Buffer)', () async {
      final geo = GeoEngine(apiKey: 'test-key');
      await geo.sendLocation(
          deviceId: 'device-test-01', latitude: 10.0, longitude: 20.0);

      Box box = Hive.isBoxOpen('geo_engine_buffer')
          ? Hive.box('geo_engine_buffer')
          : await Hive.openBox('geo_engine_buffer');

      expect(box.length, 1);
    });

    test('El SDK debería acumular múltiples pings en el buffer', () async {
      final geo = GeoEngine(apiKey: 'test-key');
      await geo.sendLocation(deviceId: 'd1', latitude: 10, longitude: 10);
      await geo.sendLocation(deviceId: 'd1', latitude: 11, longitude: 11);
      await geo.sendLocation(deviceId: 'd1', latitude: 12, longitude: 12);

      Box box = Hive.isBoxOpen('geo_engine_buffer')
          ? Hive.box('geo_engine_buffer')
          : await Hive.openBox('geo_engine_buffer');

      expect(box.length, 3);
    });

    test('Si el servidor responde 200 OK, el buffer debería vaciarse',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"status": "success"}', 200);
      });

      final geo = GeoEngine(apiKey: 'test-key', client: mockClient);
      await geo.sendLocation(
          deviceId: 'device-success', latitude: 40.0, longitude: -3.0);

      await Future.delayed(const Duration(milliseconds: 200));

      Box box = Hive.isBoxOpen('geo_engine_buffer')
          ? Hive.box('geo_engine_buffer')
          : await Hive.openBox('geo_engine_buffer');

      expect(box.length, 0);
    });

    test('El SDK debería incluir el header de Integridad al enviar datos',
        () async {
      final mockClient = MockClient((request) async {
        final tokenHeader = request.headers['X-Device-Integrity'];

        if (tokenHeader == "token_de_prueba_simulado_12345") {
          return http.Response('{"status": "success"}', 200);
        } else {
          return http.Response('Falta token', 403);
        }
      });

      final geo = GeoEngine(
        apiKey: 'test-key',
        androidCloudProjectNumber: '123456',
        client: mockClient,
      );

      await geo.sendLocation(
          deviceId: 'device-secure', latitude: 50.0, longitude: 50.0);

      await Future.delayed(const Duration(milliseconds: 200));

      Box box = Hive.isBoxOpen('geo_engine_buffer')
          ? Hive.box('geo_engine_buffer')
          : await Hive.openBox('geo_engine_buffer');

      expect(box.length, 0,
          reason: 'El servidor debería aceptar el envío con el token mockeado');
    });
  });

  tearDownAll(() async {
    try {
      await Hive.close();
      await Hive.deleteFromDisk();
    } catch (e) {}
  });
}
