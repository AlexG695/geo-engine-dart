/// Base exception class for all errors originating from the GeoEngine SDK.
sealed class GeoEngineException implements Exception {
  /// Human-readable explanation of the operational failure.
  final String message;

  /// Optional HTTP or gRPC response status code associated with the error.
  final int? statusCode;

  /// Creates a new [GeoEngineException] instance.
  const GeoEngineException(this.message, {this.statusCode});

  @override
  String toString() =>
      'GeoEngineException: $message ${statusCode != null ? '(Status: $statusCode)' : ''}';
}

/// Exception thrown when gRPC or HTTP network operations fail.
final class TransportException extends GeoEngineException {
  /// Creates a [TransportException] with a message and optional status code.
  const TransportException(super.message, {super.statusCode});
}

/// Exception thrown when Google Play Integrity or Apple App Attest attestation is rejected.
final class IntegrityVerificationException extends GeoEngineException {
  /// Creates an [IntegrityVerificationException] with detailed attestation context.
  const IntegrityVerificationException(super.message, {super.statusCode});
}
