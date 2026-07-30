/// The official GeoEngine Flutter SDK.
///
/// Provides real-time background location tracking, local offline buffering,
/// and Play Integrity/App Attest attestation for B2B spatial operations.
library geo_engine_sdk;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'src/auth/integrity_auth_manager.dart';
import 'src/models/location_ping.dart';
import 'src/models/sdk_exceptions.dart';
import 'src/transport/grpc_batch_transport.dart';

export 'src/models/location_ping.dart';
export 'src/models/sdk_exceptions.dart';
export 'src/version.dart';
export 'src/transport/grpc_batch_transport.dart' show BaseGrpcTransport;

/// Main entry point for the GeoEngine SDK.
class GeoEngine {
  static const String _boxName = 'geo_engine_buffer';

  /// API Key used for project authentication.
  final String apiKey;

  /// Base URL for administrative services and device integrity verification.
  final String managementUrl;

  /// Host name for the gRPC location ingestion server.
  final String grpcHost;

  /// Port number for gRPC calls (defaults to 443).
  final int grpcPort;

  /// Network request timeout.
  final Duration timeout;

  /// Enables verbose console logging when `true`.
  final bool debug;

  /// Cloud project number used for Android Play Integrity API checks.
  final String? androidCloudProjectNumber;

  late final IntegrityAuthManager _authManager;
  late final BaseGrpcTransport _transport;

  Box<LocationPing>? _bufferBox;
  StreamSubscription? _networkSubscription;
  bool _isFlushing = false;
  late final Future<String> _appNameFuture;

  /// Internal flag for simulating Android behavior in unit tests.
  @visibleForTesting
  static bool? debugSimulateAndroid;

  /// Initializes persistent Hive storage required by the SDK.
  ///
  /// Must be invoked prior to instantiating [GeoEngine].
  static Future<void> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LocationPingAdapter());
    }
    await Hive.openBox<LocationPing>(_boxName);
  }

  /// Constructs a [GeoEngine] client instance.
  GeoEngine({
    required this.apiKey,
    required this.grpcHost,
    this.grpcPort = 443,
    String? managementUrl,
    this.timeout = const Duration(seconds: 10),
    this.debug = false,
    this.androidCloudProjectNumber,
    BaseGrpcTransport? transportOverride,
    http.Client? httpClientOverride,
  }) : managementUrl = managementUrl ?? 'https://api.geoengine.dev' {
    _appNameFuture = _resolveAppName();
    _authManager = IntegrityAuthManager(
      managementUrl: this.managementUrl,
      apiKey: apiKey,
      androidCloudProjectNumber: androidCloudProjectNumber,
      httpClient: httpClientOverride,
    );
    _transport = transportOverride ??
        GrpcTransport(
          host: grpcHost,
          port: grpcPort,
          useSecureChannel: true,
        );
    _initInternals();
  }

  void _initInternals() async {
    if (Hive.isBoxOpen(_boxName)) {
      _bufferBox = Hive.box<LocationPing>(_boxName);
    } else {
      _bufferBox = await Hive.openBox<LocationPing>(_boxName);
    }

    _networkSubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        flushBuffer();
      }
    });
  }

  Future<String> _resolveAppName() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (packageInfo.appName.isNotEmpty) {
        return packageInfo.appName;
      }
      if (packageInfo.packageName.isNotEmpty) {
        return packageInfo.packageName;
      }
    } catch (_) {
      // Fall back to a stable default when package metadata is unavailable.
    }

    return 'dev.geoengine.app';
  }

  /// Buffers and transmits a single spatial coordinate update to GeoEngine.
  ///
  /// If the network is unavailable, the coordinate is stored in local storage
  /// and automatically synchronized once connectivity is restored.
  Future<void> sendLocation({
    required String deviceId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required double speed,
    required double heading,
    int? timestamp,
    bool isMocked = false,
  }) async {
    final ping = LocationPing(
      deviceId: deviceId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      speed: speed,
      heading: heading,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      isMocked: isMocked,
    );

    final connectivity = await Connectivity().checkConnectivity();
    final bool isOffline = connectivity.contains(ConnectivityResult.none);

    if (isOffline || (_bufferBox != null && _bufferBox!.isNotEmpty)) {
      await _enqueuePing(ping);
      if (!isOffline) {
        await flushBuffer();
      }
      return;
    }

    final appName = await _appNameFuture;

    try {
      final jwt = await _authManager.getOrRefreshSessionJwt(
        deviceId: deviceId,
        packageName: appName,
      );

      final bool success = await _transport.sendSinglePing(
        ping: ping,
        jwtToken: jwt,
      );

      if (!success) {
        if (debug) debugPrint('[GeoEngine] Direct send failed. Buffering...');
        await _enqueuePing(ping);
      }
    } on TransportException catch (e) {
      if (e.statusCode == 401) {
        await _authManager.getOrRefreshSessionJwt(
          deviceId: deviceId,
          packageName: appName,
          forceRefresh: true,
        );
      }
      await _enqueuePing(ping);
    } catch (_) {
      await _enqueuePing(ping);
    }
  }

  Future<void> _enqueuePing(LocationPing ping) async {
    if (_bufferBox != null) {
      await _bufferBox!.add(ping);
    }
  }

  /// Transmits buffered location pings accumulated in local storage to the server.
  Future<void> flushBuffer() async {
    if (_bufferBox == null || _bufferBox!.isEmpty || _isFlushing) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    _isFlushing = true;

    try {
      final batch = _bufferBox!.values.take(100).toList();
      if (batch.isEmpty) return;

      final deviceId = batch.first.deviceId;
      final appName = await _appNameFuture;
      final jwt = await _authManager.getOrRefreshSessionJwt(
        deviceId: deviceId,
        packageName: appName,
      );

      final bool success = await _transport.sendBatchWithRetry(
        pings: batch,
        jwtToken: jwt,
      );

      if (success) {
        final keysToDelete = _bufferBox!.keys.take(batch.length).toList();
        await _bufferBox!.deleteAll(keysToDelete);

        if (_bufferBox!.isNotEmpty) {
          _isFlushing = false;
          await flushBuffer();
        }
      }
    } catch (_) {
    } finally {
      _isFlushing = false;
    }
  }

  /// Cancels active network listeners and closes underlying connections.
  void close() {
    _networkSubscription?.cancel();
    _transport.close();
  }
}
