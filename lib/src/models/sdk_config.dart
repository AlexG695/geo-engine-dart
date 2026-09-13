import '../../geo_engine_sdk.dart';

/// Configuration options used to initialize a [GeoEngine] instance.
class SDKConfig {
  /// The secret API key used for authentication.
  final String apiKey;

  /// The base URL of the management and authentication service.
  final String managementUrl;

  /// The host name for the gRPC location ingestion server.
  final String grpcHost;

  /// The port number for gRPC calls.
  final int grpcPort;

  /// The network request timeout duration.
  final Duration timeout;

  /// Whether verbose console logging is enabled.
  final bool debug;

  /// The Google Cloud project number required for Android Play Integrity checks.
  final String? androidCloudProjectNumber;

  /// Creates a configuration instance for [GeoEngine].
  const SDKConfig({
    required this.apiKey,
    required this.grpcHost,
    this.grpcPort = 443,
    this.managementUrl = 'https://management.geoengine.dev',
    this.timeout = const Duration(seconds: 10),
    this.debug = false,
    this.androidCloudProjectNumber,
  });
}
