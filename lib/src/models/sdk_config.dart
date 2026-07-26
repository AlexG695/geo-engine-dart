// lib/src/models/sdk_config.dart

class SDKConfig {
  final String apiKey;

  final String managementUrl;

  final String grpcHost;

  final int grpcPort;

  final Duration timeout;

  final bool debug;

  final String? androidCloudProjectNumber;

  /// Creates a configuration instance for [GeoEngine].
  const SDKConfig({
    required this.apiKey,
    required this.grpcHost,
    this.grpcPort = 443,
    this.managementUrl = 'https://api.geoengine.dev',
    this.timeout = const Duration(seconds: 10),
    this.debug = false,
    this.androidCloudProjectNumber,
  });
}
