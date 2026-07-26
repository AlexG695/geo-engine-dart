// This is a generated file - do not edit.
//
// Generated from geo_ingest.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use locationPingDescriptor instead')
const LocationPing$json = {
  '1': 'LocationPing',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'latitude', '3': 2, '4': 1, '5': 1, '10': 'latitude'},
    {'1': 'longitude', '3': 3, '4': 1, '5': 1, '10': 'longitude'},
    {'1': 'accuracy', '3': 4, '4': 1, '5': 1, '10': 'accuracy'},
    {'1': 'speed', '3': 5, '4': 1, '5': 1, '10': 'speed'},
    {'1': 'heading', '3': 6, '4': 1, '5': 1, '10': 'heading'},
    {'1': 'timestamp', '3': 7, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'is_mocked', '3': 8, '4': 1, '5': 8, '10': 'isMocked'},
  ],
};

/// Descriptor for `LocationPing`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List locationPingDescriptor = $convert.base64Decode(
    'CgxMb2NhdGlvblBpbmcSGwoJZGV2aWNlX2lkGAEgASgJUghkZXZpY2VJZBIaCghsYXRpdHVkZR'
    'gCIAEoAVIIbGF0aXR1ZGUSHAoJbG9uZ2l0dWRlGAMgASgBUglsb25naXR1ZGUSGgoIYWNjdXJh'
    'Y3kYBCABKAFSCGFjY3VyYWN5EhQKBXNwZWVkGAUgASgBUgVzcGVlZBIYCgdoZWFkaW5nGAYgAS'
    'gBUgdoZWFkaW5nEhwKCXRpbWVzdGFtcBgHIAEoA1IJdGltZXN0YW1wEhsKCWlzX21vY2tlZBgI'
    'IAEoCFIIaXNNb2NrZWQ=');

@$core.Deprecated('Use locationBatchRequestDescriptor instead')
const LocationBatchRequest$json = {
  '1': 'LocationBatchRequest',
  '2': [
    {
      '1': 'pings',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.geoengine.v1.LocationPing',
      '10': 'pings'
    },
  ],
};

/// Descriptor for `LocationBatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List locationBatchRequestDescriptor = $convert.base64Decode(
    'ChRMb2NhdGlvbkJhdGNoUmVxdWVzdBIwCgVwaW5ncxgBIAMoCzIaLmdlb2VuZ2luZS52MS5Mb2'
    'NhdGlvblBpbmdSBXBpbmdz');

@$core.Deprecated('Use ingestResponseDescriptor instead')
const IngestResponse$json = {
  '1': 'IngestResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'processed_count', '3': 2, '4': 1, '5': 3, '10': 'processedCount'},
    {'1': 'error_message', '3': 3, '4': 1, '5': 9, '10': 'errorMessage'},
  ],
};

/// Descriptor for `IngestResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ingestResponseDescriptor = $convert.base64Decode(
    'Cg5Jbmdlc3RSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEicKD3Byb2Nlc3NlZF'
    '9jb3VudBgCIAEoA1IOcHJvY2Vzc2VkQ291bnQSIwoNZXJyb3JfbWVzc2FnZRgDIAEoCVIMZXJy'
    'b3JNZXNzYWdl');
