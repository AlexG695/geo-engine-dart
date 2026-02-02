import 'package:flutter/material.dart';
import 'package:geo_engine_sdk/geo_engine_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Idle';

  GeoEngine? _geoEngine;

  @override
  void initState() {
    super.initState();
    _initSdk();
  }

  Future<void> _initSdk() async {
    try {
      await GeoEngine.initialize();

      _geoEngine = GeoEngine(
        apiKey: "DEMO_API_KEY",
        debug: true,
      );

      setState(() {
        _status = 'SDK Initialized ✅';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GeoEngine Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('SDK Status: $_status'),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    _geoEngine?.sendLocation(
                      deviceId: "device_001",
                      latitude: 37.7749,
                      longitude: -122.4194,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Location sent!")),
                    );
                  },
                  child: const Text("Send Test Location"))
            ],
          ),
        ),
      ),
    );
  }
}
