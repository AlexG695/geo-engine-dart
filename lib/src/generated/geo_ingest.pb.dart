// This is a generated file - do not edit.
//
// Generated from geo_ingest.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class LocationPing extends $pb.GeneratedMessage {
  factory LocationPing({
    $core.String? deviceId,
    $core.double? latitude,
    $core.double? longitude,
    $core.double? accuracy,
    $core.double? speed,
    $core.double? heading,
    $fixnum.Int64? timestamp,
    $core.bool? isMocked,
  }) {
    final result = create();
    if (deviceId != null) result.deviceId = deviceId;
    if (latitude != null) result.latitude = latitude;
    if (longitude != null) result.longitude = longitude;
    if (accuracy != null) result.accuracy = accuracy;
    if (speed != null) result.speed = speed;
    if (heading != null) result.heading = heading;
    if (timestamp != null) result.timestamp = timestamp;
    if (isMocked != null) result.isMocked = isMocked;
    return result;
  }

  LocationPing._();

  factory LocationPing.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LocationPing.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocationPing',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'geoengine.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..aD(2, _omitFieldNames ? '' : 'latitude')
    ..aD(3, _omitFieldNames ? '' : 'longitude')
    ..aD(4, _omitFieldNames ? '' : 'accuracy')
    ..aD(5, _omitFieldNames ? '' : 'speed')
    ..aD(6, _omitFieldNames ? '' : 'heading')
    ..aInt64(7, _omitFieldNames ? '' : 'timestamp')
    ..aOB(8, _omitFieldNames ? '' : 'isMocked')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocationPing clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocationPing copyWith(void Function(LocationPing) updates) =>
      super.copyWith((message) => updates(message as LocationPing))
          as LocationPing;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocationPing create() => LocationPing._();
  @$core.override
  LocationPing createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LocationPing getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocationPing>(create);
  static LocationPing? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get latitude => $_getN(1);
  @$pb.TagNumber(2)
  set latitude($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLatitude() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatitude() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get longitude => $_getN(2);
  @$pb.TagNumber(3)
  set longitude($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLongitude() => $_has(2);
  @$pb.TagNumber(3)
  void clearLongitude() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get accuracy => $_getN(3);
  @$pb.TagNumber(4)
  set accuracy($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAccuracy() => $_has(3);
  @$pb.TagNumber(4)
  void clearAccuracy() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get speed => $_getN(4);
  @$pb.TagNumber(5)
  set speed($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSpeed() => $_has(4);
  @$pb.TagNumber(5)
  void clearSpeed() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get heading => $_getN(5);
  @$pb.TagNumber(6)
  set heading($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHeading() => $_has(5);
  @$pb.TagNumber(6)
  void clearHeading() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get timestamp => $_getI64(6);
  @$pb.TagNumber(7)
  set timestamp($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTimestamp() => $_has(6);
  @$pb.TagNumber(7)
  void clearTimestamp() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isMocked => $_getBF(7);
  @$pb.TagNumber(8)
  set isMocked($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsMocked() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsMocked() => $_clearField(8);
}

class LocationBatchRequest extends $pb.GeneratedMessage {
  factory LocationBatchRequest({
    $core.Iterable<LocationPing>? pings,
  }) {
    final result = create();
    if (pings != null) result.pings.addAll(pings);
    return result;
  }

  LocationBatchRequest._();

  factory LocationBatchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LocationBatchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LocationBatchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'geoengine.v1'),
      createEmptyInstance: create)
    ..pPM<LocationPing>(1, _omitFieldNames ? '' : 'pings',
        subBuilder: LocationPing.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocationBatchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocationBatchRequest copyWith(void Function(LocationBatchRequest) updates) =>
      super.copyWith((message) => updates(message as LocationBatchRequest))
          as LocationBatchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocationBatchRequest create() => LocationBatchRequest._();
  @$core.override
  LocationBatchRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LocationBatchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LocationBatchRequest>(create);
  static LocationBatchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<LocationPing> get pings => $_getList(0);
}

class IngestResponse extends $pb.GeneratedMessage {
  factory IngestResponse({
    $core.bool? success,
    $fixnum.Int64? processedCount,
    $core.String? errorMessage,
  }) {
    final result = create();
    if (success != null) result.success = success;
    if (processedCount != null) result.processedCount = processedCount;
    if (errorMessage != null) result.errorMessage = errorMessage;
    return result;
  }

  IngestResponse._();

  factory IngestResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'geoengine.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aInt64(2, _omitFieldNames ? '' : 'processedCount')
    ..aOS(3, _omitFieldNames ? '' : 'errorMessage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestResponse copyWith(void Function(IngestResponse) updates) =>
      super.copyWith((message) => updates(message as IngestResponse))
          as IngestResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestResponse create() => IngestResponse._();
  @$core.override
  IngestResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static IngestResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IngestResponse>(create);
  static IngestResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get processedCount => $_getI64(1);
  @$pb.TagNumber(2)
  set processedCount($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProcessedCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearProcessedCount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get errorMessage => $_getSZ(2);
  @$pb.TagNumber(3)
  set errorMessage($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErrorMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrorMessage() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
