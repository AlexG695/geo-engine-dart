/// The official GeoEngine SDK for Flutter.
///
/// Provides capabilities for location tracking, geofencing, and
/// validating device integrity.
library geo_engine;

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app_device_integrity.dart';

/// Custom exception thrown by the GeoEngine SDK when an error occurs.
class GeoEngineException implements Exception {
  /// A descriptive message of the error.
  final String message;

  /// Optional HTTP status code associated with the error.
  final int? statusCode;

  /// Creates a new [GeoEngineException].
  GeoEngineException(this.message, {this.statusCode});

  @override
  String toString() =>
      "GeoEngineException: $message ${statusCode != null ? '(Code: $statusCode)' : ''}";
}

/// The main entry point for the GeoEngine SDK.
///
/// Use this class to initialize the tracking system and handle
/// location updates securely.
class GeoEngine {
  static const String _defaultManagementUrl = 'https://api.geoengine.dev';
  static const String _defaultIngestUrl = 'https://ingest.geoengine.dev';
  static const String _boxName = 'geo_engine_buffer';
  String? _cachedIntegrityToken;
  String? _packageName;

  /// The API key used for authenticating with the GeoEngine services.
  final String apiKey;

  /// The base URL for the management API.
  final String managementUrl;

  /// The base URL for the data ingestion API.
  final String ingestUrl;

  /// The timeout duration for HTTP requests.
  final Duration timeout;

  /// Whether to enable debug logging to the console.
  final bool debug;

  /// The project number for Android Google Cloud, used for Device Integrity.
  final String? androidCloudProjectNumber;

  final http.Client _client;

  @visibleForTesting
  static bool? debugSimulateAndroid;

  Box? _bufferBox;
  StreamSubscription? _networkSubscription;
  bool _isFlushing = false;

  /// Initializes the local environment for the SDK.
  ///
  /// This method must be called before creating any instance of [GeoEngine].
  /// It initializes the local database (Hive) used for buffering location data.
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  /// Creates a new instance of [GeoEngine].
  ///
  /// - [apiKey]: Required. The API key for your GeoEngine project.
  /// - [managementUrl]: Optional. Overrides the default management API URL.
  /// - [ingestUrl]: Optional. Overrides the default ingestion API URL.
  /// - [timeout]: Connection timeout for requests (default: 10 seconds).
  /// - [debug]: If true, prints debug info to the console (default: false).
  /// - [androidCloudProjectNumber]: Required for Android apps to use Play Integrity.
  /// - [client]: Optional [http.Client] for testing.
  GeoEngine({
    required this.apiKey,
    String? managementUrl,
    String? ingestUrl,
    this.timeout = const Duration(seconds: 10),
    this.debug = false,
    this.androidCloudProjectNumber,
    http.Client? client,
  })  : managementUrl = managementUrl ?? _defaultManagementUrl,
        ingestUrl = ingestUrl ?? _defaultIngestUrl,
        _client = client ?? http.Client() {
    _initInternals();
  }

  /// Initializes the SDK with your API Key.
  ///
  /// Throws an [Exception] if the key is invalid.
  void _initInternals() async {
    if (Hive.isBoxOpen(_boxName)) {
      _bufferBox = Hive.box(_boxName);
    } else {
      _bufferBox = await Hive.openBox(_boxName);
    }

    _networkSubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      bool hasInternet = !results.contains(ConnectivityResult.none);

      if (hasInternet) {
        if (debug) {
          print('[GeoEngine] Conexión detectada. Sincronizando buffer...');
        }
        _flushBuffer();
      }
    });
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _packageName = packageInfo.packageName;
  }

  /// Sends a location point to the GeoEngine system.
  ///
  /// The data is first stored in a persistent local buffer to ensure
  /// it is not lost if there is no internet connection. Then, it attempts
  /// to automatically synchronize the buffer.
  ///
  /// Parameters:
  /// - [deviceId]: Unique identifier for the device.
  /// - [latitude]: Latitude in decimal degrees.
  /// - [longitude]: Longitude in decimal degrees.
  /// - [timestamp]: (Optional) Time of the reading in seconds since Unix epoch.
  ///   If omitted, `DateTime.now()` is used.
  Future<void> sendLocation({
    required String deviceId,
    required double latitude,
    required double longitude,
    int? timestamp,
  }) async {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final data = {
      'device_id': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp':
          DateTime.fromMillisecondsSinceEpoch(ts * 1000).toIso8601String(),
    };

    if (_bufferBox != null) {
      await _bufferBox!.add(data);
      if (debug) {
        print(
            '[GeoEngine] Ping guardado. Buffer: ${_bufferBox!.length} items.');
      }
    }

    _flushBuffer();
  }

  Future<void> _ensureIntegrityToken() async {
    if (_cachedIntegrityToken != null) return;

    try {
      _cachedIntegrityToken = await AppDeviceIntegrity.generateIntegrityToken(
        cloudProjectNumber: androidCloudProjectNumber,
      );
      if (debug) {
        print('[GeoEngine] Token de integridad generado exitosamente.');
      }
    } catch (e) {
      if (debug) {
        print('GeoEngine Warning: No se pudo verificar integridad: $e');
      }
    }
  }

  /// Synchronizes the points accumulated in the local buffer with the server.
  ///
  /// This method is called automatically after [sendLocation] or when
  /// internet connectivity is recovered.
  ///
  /// The process includes:
  /// 1. Connectivity check.
  /// 2. Generation/verification of the integrity token (App Attest/Play Integrity).
  /// 3. Batch transmission to the ingest endpoint.
  /// 4. Clearing the buffer if the response is successful (200-299).
  ///
  /// If a 403 error occurs, an integrity problem is assumed and the token is recycled.
  Future<void> _flushBuffer() async {
    if (_bufferBox == null || _bufferBox!.isEmpty || _isFlushing) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (debug) print('[GeoEngine] Sin internet. Datos permanecen en local.');
      return;
    }

    _isFlushing = true;

    try {
      await _ensureIntegrityToken();
      final rawData = _bufferBox!.values.toList();

      final batchPayload = rawData.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return {
          'device_id': map['device_id'],
          'lat': map['latitude'],
          'lng': map['longitude'],
          'timestamp': map['timestamp']
        };
      }).toList();

      if (debug) {
        print('[GeoEngine] Enviando batch de ${batchPayload.length} puntos...');
      }

      final uri = Uri.parse('$ingestUrl/v1/ingest/batch');

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(batchPayload),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (debug) {
          print('[GeoEngine] Batch enviado exitosamente. Limpiando buffer.');
        }
        await _bufferBox!.clear();
      } else if (response.statusCode == 403) {
        if (debug) {
          print(
              '[GeoEngine] 403 Forbidden (Integridad/Auth). Reseteando token para el próximo intento.');
        }
        _cachedIntegrityToken = null;
      } else {
        if (debug) {
          print(
              '[GeoEngine] Error Servidor (${response.statusCode}): ${response.body}');
        }
      }
    } catch (e) {
      if (debug) print('[GeoEngine] Error de Red al sincronizar: $e');
    } finally {
      _isFlushing = false;
    }
  }

  /// Creates a new geofence polygon.
  ///
  /// - [name]: A human-readable name for the geofence.
  /// - [coordinates]: A list of `[latitude, longitude]` pairs defining the polygon.
  ///   Must contain at least 3 points.
  /// - [webhookUrl]: The URL that will receive events when this geofence is triggered.
  ///
  /// Returns a [Map] containing the server response.
  ///
  /// Throws a [GeoEngineException] if the input is invalid or the server request fails.
  Future<Map<String, dynamic>> createGeofence({
    required String name,
    required List<List<double>> coordinates,
    required String webhookUrl,
  }) async {
    if (coordinates.length < 3) {
      throw GeoEngineException(
          "Se requieren al menos 3 puntos para un polígono");
    }

    final polygon = coordinates.map((p) => [p[1], p[0]]).toList();

    if (polygon.first[0] != polygon.last[0] ||
        polygon.first[1] != polygon.last[1]) {
      polygon.add(polygon.first);
    }

    final payload = {
      "name": name,
      "webhook_url": webhookUrl,
      "geojson": {
        "type": "Polygon",
        "coordinates": [polygon]
      }
    };

    final uri = Uri.parse('$managementUrl/geofences');

    if (debug) print('[GeoEngine] Creating geofence: $name');

    try {
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      if (response.statusCode >= 400) {
        throw GeoEngineException('Management Error: ${response.body}',
            statusCode: response.statusCode);
      }

      return jsonDecode(response.body);
    } on TimeoutException {
      throw GeoEngineException('Connection timed out');
    } catch (e) {
      if (debug) print('[GeoEngine] Error: $e');
      rethrow;
    }
  }

  Map<String, String> get _headers {
    final isAndroid = debugSimulateAndroid ?? Platform.isAndroid;
    final isIOS =
        !isAndroid && (debugSimulateAndroid == false ? true : Platform.isIOS);

    return {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'User-Agent': 'GeoEngineFlutter/1.1.11',
      if (isAndroid) ...{
        'X-Platform': 'Android',
        'X-Android-Package': _packageName ?? '',
        if (_cachedIntegrityToken != null)
          'X-Device-Integrity': _cachedIntegrityToken!,
      },
      if (isIOS) ...{
        'X-IOS-Bundle-ID': _packageName ?? '',
        'X-Platform': 'iOS',
      }
    };
  }

  /// Closes the SDK instance and releases resources.
  ///
  /// Cancels network connectivity subscriptions and closes the HTTP client.
  void close() {
    _networkSubscription?.cancel();
    _client.close();
  }
}
