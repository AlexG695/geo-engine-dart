library geo_engine;

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

/// Excepción personalizada para errores del SDK
class GeoEngineException implements Exception {
  final String message;
  final int? statusCode;

  GeoEngineException(this.message, {this.statusCode});

  @override
  String toString() => "GeoEngineException: $message ${statusCode != null ? '(Code: $statusCode)' : ''}";
}

/// Cliente oficial para interactuar con la plataforma Geo-Engine.
class GeoEngine {
  static const String _defaultManagementUrl = 'https://api.geo-engine.dev';
  static const String _defaultIngestUrl = 'https://ingest.geo-engine.dev';

  final String apiKey;
  final String managementUrl;
  final String ingestUrl;
  final Duration timeout;
  final bool debug;
  final http.Client _client;

  /// Crea una nueva instancia del cliente.
  ///
  /// [apiKey] es obligatoria.
  /// [timeout] define el tiempo máximo de espera (default: 10s).
  /// [debug] si es true, imprime logs en la consola.
  GeoEngine({
    required this.apiKey,
    this.managementUrl = _defaultManagementUrl,
    this.ingestUrl = _defaultIngestUrl,
    this.timeout = const Duration(seconds: 10),
    this.debug = false,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<void> sendLocation({
    required String deviceId,
    required double latitude,
    required double longitude,
    int? timestamp,
  }) async {
    final uri = Uri.parse('$ingestUrl/ingest');
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final body = jsonEncode({
      'device_id': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': ts,
    });

    if (debug) print('📡 [GeoEngine] Sending location for $deviceId...');

    try {
      final response = await _client.post(
        uri,
        headers: _headers,
        body: body,
      ).timeout(timeout);

      if (response.statusCode >= 400) {
        throw GeoEngineException(
          'Ingest Failed: ${response.body}', 
          statusCode: response.statusCode
        );
      }
      
      if (debug) print('[GeoEngine] Location sent successfully.');

    } on TimeoutException {
      throw GeoEngineException('Connection timed out after ${timeout.inSeconds}s');
    } catch (e) {
      if (debug) print('[GeoEngine] Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createGeofence({
    required String name,
    required List<List<double>> coordinates,
    required String webhookUrl,
  }) async {
    if (coordinates.length < 3) {
      throw GeoEngineException("Se requieren al menos 3 puntos para un polígono");
    }

    // Convertir formato: Flutter [Lat, Lng] -> GeoJSON [Lng, Lat]
    final polygon = coordinates.map((p) => [p[1], p[0]]).toList();

    // Cerrar el polígono si no está cerrado
    if (polygon.first[0] != polygon.last[0] || polygon.first[1] != polygon.last[1]) {
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
      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(timeout);

      if (response.statusCode >= 400) {
        throw GeoEngineException(
          'Management Error: ${response.body}',
          statusCode: response.statusCode
        );
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
    'User-Agent': 'GeoEngineFlutter/1.0.3',
  };

  void close() {
    _client.close();
  }
}