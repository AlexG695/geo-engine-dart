import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Interface for components providing valid bearer tokens.
abstract class TokenProvider {
  /// Returns a valid JWT bearer token, obtaining or refreshing it if expired.
  Future<String> getValidToken({bool forceRefresh = false});

  /// Invalidates the currently cached token so subsequent requests trigger a refresh.
  void invalidateToken();
}

/// An [http.BaseClient] implementation enforcing Zero Trust compliance for M2M communication.
///
/// Automatically signs outgoing HTTP requests with HMAC SHA-256 signatures,
/// injects Machine-to-Machine headers (`X-Client-ID`, `X-Signature`, `X-Request-Time`),
/// attaches Bearer JWT authorization, and transparently retries requests on HTTP 401.
class ZeroTrustAuthClient extends http.BaseClient {
  final http.Client _inner;
  final TokenProvider _tokenProvider;

  /// The machine or client identifier used in M2M requests.
  final String clientId;

  /// The shared device secret used for HMAC signature generation.
  final String deviceSecret;

  /// The target deployment environment.
  final String environment;

  /// Creates a [ZeroTrustAuthClient] instance.
  ZeroTrustAuthClient({
    required TokenProvider tokenProvider,
    required this.clientId,
    required this.deviceSecret,
    this.environment = 'live',
    http.Client? innerClient,
  })  : _tokenProvider = tokenProvider,
        _inner = innerClient ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _tokenProvider.getValidToken();
    final now = DateTime.now().millisecondsSinceEpoch;
    _signAndInjectHeaders(request, token: token, timestampMs: now);

    final isRetryable = request is http.Request;
    http.Request? originalRequestCopy;
    if (isRetryable) {
      originalRequestCopy = _copyRequest(request);
    }

    var response = await _inner.send(request);

    if (response.statusCode == 401 &&
        isRetryable &&
        originalRequestCopy != null) {
      _tokenProvider.invalidateToken();
      final freshToken = await _tokenProvider.getValidToken(forceRefresh: true);

      final retryRequest = _copyRequest(originalRequestCopy);
      final retryNow = DateTime.now().millisecondsSinceEpoch;
      _signAndInjectHeaders(retryRequest,
          token: freshToken, timestampMs: retryNow);

      response = await _inner.send(retryRequest);
    }

    return response;
  }

  void _signAndInjectHeaders(
    http.BaseRequest request, {
    required String token,
    required int timestampMs,
  }) {
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (clientId.isNotEmpty) {
      request.headers['X-Client-ID'] = clientId;
    }
    request.headers['X-Geo-Environment'] = environment;
    request.headers['X-Request-Time'] = timestampMs.toString();

    if (deviceSecret.isNotEmpty) {
      final signature = generateHmacSignature(
        secret: deviceSecret,
        clientId: clientId,
        timestampMs: timestampMs,
        path: request.url.path,
      );
      request.headers['X-Signature'] = signature;
    }
  }

  /// Generates an HMAC-SHA256 signature for machine assertion.
  static String generateHmacSignature({
    required String secret,
    required String clientId,
    required int timestampMs,
    String? path,
  }) {
    final key = utf8.encode(secret);
    final payload = path != null && path.isNotEmpty
        ? '$timestampMs:$clientId:$path'
        : '$timestampMs:$clientId';
    return Hmac(sha256, key).convert(utf8.encode(payload)).toString();
  }

  http.Request _copyRequest(http.Request req) {
    final copy = http.Request(req.method, req.url)
      ..bodyBytes = req.bodyBytes
      ..encoding = req.encoding
      ..followRedirects = req.followRedirects
      ..maxRedirects = req.maxRedirects
      ..persistentConnection = req.persistentConnection;
    copy.headers.addAll(req.headers);
    return copy;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
