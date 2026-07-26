// This is a generated file - do not edit.
//
// Generated from geo_ingest.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'geo_ingest.pb.dart' as $0;

export 'geo_ingest.pb.dart';

@$pb.GrpcServiceName('geoengine.v1.GeoIngestService')
class GeoIngestServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  GeoIngestServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.IngestResponse> sendSingleLocation(
    $0.LocationPing request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendSingleLocation, request, options: options);
  }

  $grpc.ResponseFuture<$0.IngestResponse> sendBatchLocation(
    $0.LocationBatchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendBatchLocation, request, options: options);
  }

  // method descriptors

  static final _$sendSingleLocation =
      $grpc.ClientMethod<$0.LocationPing, $0.IngestResponse>(
          '/geoengine.v1.GeoIngestService/SendSingleLocation',
          ($0.LocationPing value) => value.writeToBuffer(),
          $0.IngestResponse.fromBuffer);
  static final _$sendBatchLocation =
      $grpc.ClientMethod<$0.LocationBatchRequest, $0.IngestResponse>(
          '/geoengine.v1.GeoIngestService/SendBatchLocation',
          ($0.LocationBatchRequest value) => value.writeToBuffer(),
          $0.IngestResponse.fromBuffer);
}

@$pb.GrpcServiceName('geoengine.v1.GeoIngestService')
abstract class GeoIngestServiceBase extends $grpc.Service {
  $core.String get $name => 'geoengine.v1.GeoIngestService';

  GeoIngestServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.LocationPing, $0.IngestResponse>(
        'SendSingleLocation',
        sendSingleLocation_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LocationPing.fromBuffer(value),
        ($0.IngestResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LocationBatchRequest, $0.IngestResponse>(
        'SendBatchLocation',
        sendBatchLocation_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.LocationBatchRequest.fromBuffer(value),
        ($0.IngestResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.IngestResponse> sendSingleLocation_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LocationPing> $request) async {
    return sendSingleLocation($call, await $request);
  }

  $async.Future<$0.IngestResponse> sendSingleLocation(
      $grpc.ServiceCall call, $0.LocationPing request);

  $async.Future<$0.IngestResponse> sendBatchLocation_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.LocationBatchRequest> $request) async {
    return sendBatchLocation($call, await $request);
  }

  $async.Future<$0.IngestResponse> sendBatchLocation(
      $grpc.ServiceCall call, $0.LocationBatchRequest request);
}
