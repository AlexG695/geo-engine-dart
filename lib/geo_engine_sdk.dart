library geo_engine;

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class GeoEngineException implements Exception {
  final String message;
  final int? statusCode;

  GeoEngineException(this.message, {this.statusCode});

  @override
  String toString() =>
      "GeoEngineException: $message ${statusCode != null ? '(Code: $statusCode)' : ''}";
}

class GeoEngine {
  static const String _defaultManagementUrl = 'https://api.geo-engine.dev';
  static const String _defaultIngestUrl = 'https://ingest.geo-engine.dev';
  static const String _boxName = 'geo_engine_buffer';

  final String apiKey;
  final String managementUrl;
  final String ingestUrl;
  final Duration timeout;
  final bool debug;
  final http.Client _client;

  Box? _bufferBox;
  StreamSubscription? _networkSubscription;
  bool _isFlushing = false;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  GeoEngine({
    required this.apiKey,
    this.managementUrl = _defaultManagementUrl,
    this.ingestUrl = _defaultIngestUrl,
    this.timeout = const Duration(seconds: 10),
    this.debug = false,
    http.Client? client,
  }) : _client = client ?? http.Client() {
    _initInternals();
  }

  void _initInternals() async {
    if (Hive.isBoxOpen(_boxName)) {
      _bufferBox = Hive.box(_boxName);
    } else {
      _bufferBox = await Hive.openBox(_boxName);
    }

    _networkSubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      bool hasInternet = result != ConnectivityResult.none;

      if (hasInternet) {
        if (debug)
          print('[GeoEngine] Conexión detectada. Sincronizando buffer...');
        _flushBuffer();
      }
    });
  }

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
      if (debug)
        print(
            '[GeoEngine] Ping guardado. Buffer: ${_bufferBox!.length} items.');
    }

    _flushBuffer();
  }

  Future<void> _flushBuffer() async {
    if (_bufferBox == null || _bufferBox!.isEmpty || _isFlushing) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (debug) print('[GeoEngine] Sin internet. Datos permanecen en local.');
      return;
    }

    _isFlushing = true;

    try {
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

      if (debug)
        print('[GeoEngine] Enviando batch de ${batchPayload.length} puntos...');

      final uri = Uri.parse('$ingestUrl/v1/ingest/batch');

      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(batchPayload),
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (debug)
          print('[GeoEngine] Batch enviado exitosamente. Limpiando buffer.');
        await _bufferBox!.clear();
      } else {
        if (debug)
          print(
              '[GeoEngine] Error Servidor (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (debug) print('[GeoEngine] Error de Red al sincronizar: $e');
    } finally {
      _isFlushing = false;
    }
  }

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

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
        'User-Agent': 'GeoEngineFlutter/1.1.0',
      };

  void close() {
    _networkSubscription?.cancel();
    _client.close();
  }
}
