import 'dart:io';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_engine_sdk/geo_engine_sdk.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';

  @override
  Future<String?> getTemporaryPath() async => '.';
}

class MockConnectivityPlatform extends ConnectivityPlatform {
  List<ConnectivityResult> currentConnectivity = [ConnectivityResult.wifi];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      currentConnectivity;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value(currentConnectivity);
}

class MockGrpcTransport implements BaseGrpcTransport {
  bool shouldSucceed = true;

  @override
  Future<bool> sendSinglePing({
    required LocationPing ping,
    required String jwtToken,
  }) async =>
      shouldSucceed;

  @override
  Future<bool> sendBatchWithRetry({
    required List<LocationPing> pings,
    required String jwtToken,
    int maxRetries = 3,
  }) async =>
      shouldSucceed;

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockConnectivityPlatform mockConnectivity;
  late MockGrpcTransport mockGrpcTransport;

  setUpAll(() async {
    PathProviderPlatform.instance = MockPathProvider();
    mockConnectivity = MockConnectivityPlatform();
    ConnectivityPlatform.instance = mockConnectivity;

    final Directory tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);

    FlutterSecureStorage.setMockInitialValues({});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('app_device_integrity'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'generateIntegrityToken') {
          return "mock_play_integrity_token_12345";
        }
        return null;
      },
    );
  });

  setUp(() async {
    mockGrpcTransport = MockGrpcTransport();

    PackageInfo.setMockInitialValues(
      appName: 'GeoEngine Test App',
      packageName: 'dev.geoengine.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    GeoEngine.debugSimulateAndroid = true;

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LocationPingAdapter());
    }

    if (!Hive.isBoxOpen('geo_engine_buffer')) {
      await Hive.openBox<LocationPing>('geo_engine_buffer');
    }
    await Hive.box<LocationPing>('geo_engine_buffer').clear();
  });

  tearDown(() async {
    GeoEngine.debugSimulateAndroid = null;
    if (Hive.isBoxOpen('geo_engine_buffer')) {
      await Hive.box<LocationPing>('geo_engine_buffer').clear();
    }
  });

  MockClient createMockHttpClient() {
    return MockClient((http.Request request) async {
      final url = request.url.toString();

      if (url.contains('/api/v1/device/challenge')) {
        return http.Response('{"nonce": "mock_nonce_98765"}', 200);
      }

      if (url.contains('/api/v1/device/verify')) {
        return http.Response(
          '{"status": "verified", "jwt": "valid_mock_jwt_xyz", "expires_in": 3600}',
          200,
        );
      }

      return http.Response('Not Found', 404);
    });
  }

  group('GeoEngine SDK - Resiliencia y Persistencia Offline', () {
    test('Guarda el ping en Hive cuando el dispositivo no tiene red', () async {
      mockConnectivity.currentConnectivity = [ConnectivityResult.none];

      final geo = GeoEngine(
        apiKey: 'test_api_key',
        grpcHost: 'localhost',
        transportOverride: mockGrpcTransport,
        httpClientOverride: createMockHttpClient(),
        debug: true,
      );

      await geo.sendLocation(
        deviceId: 'device_01',
        latitude: 19.4326,
        longitude: -99.1332,
        accuracy: 5.0,
        speed: 12.5,
        heading: 180.0,
      );

      final Box<LocationPing> box = Hive.box<LocationPing>('geo_engine_buffer');
      expect(box.length, 1);
      expect(box.getAt(0)?.deviceId, 'device_01');
    });

    test('Acumula múltiples pings secuenciales en el búfer local', () async {
      mockConnectivity.currentConnectivity = [ConnectivityResult.none];

      final geo = GeoEngine(
        apiKey: 'test_api_key',
        grpcHost: 'localhost',
        transportOverride: mockGrpcTransport,
        httpClientOverride: createMockHttpClient(),
      );

      await geo.sendLocation(
        deviceId: 'device_01',
        latitude: 19.4326,
        longitude: -99.1332,
        accuracy: 4.0,
        speed: 10.0,
        heading: 90.0,
      );

      await geo.sendLocation(
        deviceId: 'device_01',
        latitude: 19.4330,
        longitude: -99.1335,
        accuracy: 3.5,
        speed: 11.2,
        heading: 92.0,
      );

      final Box<LocationPing> box = Hive.box<LocationPing>('geo_engine_buffer');
      expect(box.length, 2);
    });

    test(
        'Ejecuta el Handshake de Play Integrity y vacía el búfer al sincronizar',
        () async {
      mockConnectivity.currentConnectivity = [ConnectivityResult.wifi];
      mockGrpcTransport.shouldSucceed = true;

      final geo = GeoEngine(
        apiKey: 'test_api_key',
        grpcHost: 'localhost',
        transportOverride: mockGrpcTransport,
        httpClientOverride: createMockHttpClient(),
        debug: true,
      );

      await geo.sendLocation(
        deviceId: 'device_online_01',
        latitude: 25.7617,
        longitude: -80.1918,
        accuracy: 2.0,
        speed: 0.0,
        heading: 0.0,
      );

      final Box<LocationPing> box = Hive.box<LocationPing>('geo_engine_buffer');
      expect(box.length, 0);
    });
  });

  tearDownAll(() async {
    try {
      await Hive.close();
      await Hive.deleteFromDisk();
    } catch (_) {}
  });
}
