import 'dart:async';
import 'dart:math';
import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import '../generated/geo_ingest.pbgrpc.dart' as pb;
import '../models/location_ping.dart';
import '../models/sdk_exceptions.dart';

abstract class BaseGrpcTransport {
  Future<bool> sendSinglePing({
    required LocationPing ping,
    required String jwtToken,
  });

  Future<bool> sendBatchWithRetry({
    required List<LocationPing> pings,
    required String jwtToken,
    int maxRetries = 3,
  });

  Future<void> close();
}

class GrpcTransport implements BaseGrpcTransport {
  final String host;
  final int port;
  final bool useSecureChannel;

  ClientChannel? _channel;
  pb.GeoIngestServiceClient? _stub;

  GrpcTransport({
    required this.host,
    required this.port,
    this.useSecureChannel = true,
  });

  /// Lazily initializes and returns the underlying [ClientChannel].
  ClientChannel get _activeChannel {
    if (_channel == null) {
      final channel = ClientChannel(
        host,
        port: port,
        options: ChannelOptions(
          credentials: useSecureChannel
              ? const ChannelCredentials.secure()
              : const ChannelCredentials.insecure(),
          connectionTimeout: const Duration(seconds: 5),
        ),
      );
      _channel = channel;
      _stub = pb.GeoIngestServiceClient(channel);
    }
    return _channel!;
  }

  pb.LocationPing _mapToPbPing(LocationPing p) {
    return pb.LocationPing()
      ..deviceId = p.deviceId
      ..latitude = p.latitude
      ..longitude = p.longitude
      ..accuracy = p.accuracy
      ..speed = p.speed
      ..heading = p.heading
      ..timestamp = Int64(p.timestamp)
      ..isMocked = p.isMocked;
  }

  @override
  Future<bool> sendSinglePing({
    required LocationPing ping,
    required String jwtToken,
  }) async {
    _activeChannel;
    try {
      final response = await _stub!.sendSingleLocation(
        _mapToPbPing(ping),
        options: CallOptions(
          metadata: {'authorization': 'Bearer $jwtToken'},
          timeout: const Duration(seconds: 5),
        ),
      );
      return response.success;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unauthenticated) {
        throw const TransportException('JWT session expired', statusCode: 401);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> sendBatchWithRetry({
    required List<LocationPing> pings,
    required String jwtToken,
    int maxRetries = 3,
  }) async {
    _activeChannel;
    final requestBatch = pb.LocationBatchRequest();
    requestBatch.pings.addAll(pings.map(_mapToPbPing));

    int attempt = 0;
    bool success = false;

    while (attempt < maxRetries && !success) {
      try {
        final response = await _stub!.sendBatchLocation(
          requestBatch,
          options: CallOptions(
            metadata: {'authorization': 'Bearer $jwtToken'},
            timeout: const Duration(seconds: 10),
          ),
        );
        success = response.success;
        if (success) break;
      } on GrpcError catch (e) {
        if (e.code == StatusCode.unauthenticated) {
          throw const TransportException('JWT session expired',
              statusCode: 401);
        }
        attempt++;
        if (attempt < maxRetries) {
          await Future.delayed(
              Duration(milliseconds: pow(2, attempt).toInt() * 500));
        }
      } catch (_) {
        attempt++;
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }
    return success;
  }

  @override
  Future<void> close() async {
    await _channel?.shutdown();
    _channel = null;
    _stub = null;
  }
}
