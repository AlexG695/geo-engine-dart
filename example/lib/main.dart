import 'package:flutter/material.dart';
import 'package:geo_engine_sdk/geo_engine_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GeoEngine.initialize();

  final geoEngine = GeoEngine(
    apiKey: 'your_api_key_here',
    grpcHost: 'grpc.ingest.geoengine.dev',
    grpcPort: 443,
    debug: true,
  );

  runApp(MyApp(geoEngine: geoEngine));
}

class MyApp extends StatelessWidget {
  final GeoEngine geoEngine;

  const MyApp({super.key, required this.geoEngine});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GeoEngine SDK Example')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              await geoEngine.sendLocation(
                deviceId: 'device_demo_01',
                latitude: 37.7749,
                longitude: -122.4194,
                accuracy: 5.0,
                speed: 0.0,
                heading: 0.0,
              );
            },
            child: const Text('Send Test Location Ping'),
          ),
        ),
      ),
    );
  }
}
