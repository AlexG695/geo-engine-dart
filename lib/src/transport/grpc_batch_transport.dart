import 'dart:async';
import 'dart:math';
import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import '../auth/zero_trust_auth_client.dart';
import '../generated/geo_ingest.pbgrpc.dart' as pb;
import '../models/location_ping.dart';
import '../models/sdk_exceptions.dart';

export '../auth/zero_trust_auth_client.dart' show TokenProvider;

/// A [ClientInterceptor] that dynamically injects Bearer JWT authentication metadata.
class GrpcAuthInterceptor implements ClientInterceptor {
  /// The token provider used to obtain valid bearer tokens.
  final TokenProvider tokenProvider;

  /// Creates a [GrpcAuthInterceptor] instance.
  GrpcAuthInterceptor(this.tokenProvider);

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientUnaryInvoker<Q, R> invoker,
  ) {
    Future<void> authProvider(Map<String, String> metadata, String uri) async {
      final token = await tokenProvider.getValidToken();
      if (token.isNotEmpty) {
        metadata['authorization'] = 'Bearer $token';
      }
    }

    final newOptions = options.mergedWith(
      CallOptions(providers: [authProvider]),
    );

    return invoker(method, request, newOptions);
  }

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
    ClientMethod<Q, R> method,
    Stream<Q> requests,
    CallOptions options,
    ClientStreamingInvoker<Q, R> invoker,
  ) {
    Future<void> authProvider(Map<String, String> metadata, String uri) async {
      final token = await tokenProvider.getValidToken();
      if (token.isNotEmpty) {
        metadata['authorization'] = 'Bearer $token';
      }
    }

    final newOptions = options.mergedWith(
      CallOptions(providers: [authProvider]),
    );

    return invoker(method, requests, newOptions);
  }
}

/// Contract for transmitting spatial location coordinates over gRPC.
abstract class BaseGrpcTransport {
  /// Transmits a single [LocationPing] to the ingest endpoint.
  Future<bool> sendSinglePing({
    required LocationPing ping,
    required String jwtToken,
  });

  /// Transmits a batch of [LocationPing] instances with exponential backoff retry.
  Future<bool> sendBatchWithRetry({
    required List<LocationPing> pings,
    required String jwtToken,
    int maxRetries = 3,
  });

  /// Closes the transport channel and releases network resources.
  Future<void> close();
}

/// The gRPC transport implementation using [ClientChannel].
class GrpcTransport implements BaseGrpcTransport {
  /// The host name of the gRPC server.
  final String host;

  /// The port number of the gRPC server.
  final int port;

  /// Whether TLS encryption is enabled for the gRPC connection.
  final bool useSecureChannel;

  /// The optional token provider used by [GrpcAuthInterceptor].
  final TokenProvider? tokenProvider;

  ClientChannel? _channel;
  pb.GeoIngestServiceClient? _stub;

  /// Creates a [GrpcTransport] instance.
  GrpcTransport({
    required this.host,
    required this.port,
    this.useSecureChannel = true,
    this.tokenProvider,
  });

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
      final interceptors = <ClientInterceptor>[];
      if (tokenProvider != null) {
        interceptors.add(GrpcAuthInterceptor(tokenProvider!));
      }
      _stub = pb.GeoIngestServiceClient(channel, interceptors: interceptors);
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
      final metadata = <String, String>{};
      if (jwtToken.isNotEmpty) {
        metadata['authorization'] = 'Bearer $jwtToken';
      }
      final response = await _stub!.sendSingleLocation(
        _mapToPbPing(ping),
        options: CallOptions(
          metadata: metadata,
          timeout: const Duration(seconds: 5),
        ),
      );
      return response.success;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.unauthenticated) {
        tokenProvider?.invalidateToken();
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
        final metadata = <String, String>{};
        if (jwtToken.isNotEmpty) {
          metadata['authorization'] = 'Bearer $jwtToken';
        }
        final response = await _stub!.sendBatchLocation(
          requestBatch,
          options: CallOptions(
            metadata: metadata,
            timeout: const Duration(seconds: 10),
          ),
        );
        success = response.success;
        if (success) break;
      } on GrpcError catch (e) {
        if (e.code == StatusCode.unauthenticated) {
          tokenProvider?.invalidateToken();
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
