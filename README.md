# 📱 Geo-Engine Flutter SDK

![Build Status](https://github.com/AlexG695/geo-engine-dart/actions/workflows/flutter_test.yml/badge.svg)

The official client for integrating **real-time location tracking** into Flutter applications.

This version features an **Offline-First architecture**: it automatically persists coordinates locally when the device loses connectivity and synchronizes them via **Batch Ingestion** once the network is restored.

---

## ✨ Features

- 📍 **Smart Ingestion:** Implements "Store & Forward" logic for reliable tracking.
- ✈️ **Offline Mode:** Automatic local persistence (using Hive) when the network is unreachable.
- 🔋 **Battery Efficient:** Uses **Batching** to group updates, reducing radio usage and API overhead.
- 🔄 **Auto-Sync:** Detects network restoration and flushes the buffer automatically.
- 🔐 **Secure:** API Key authentication.
- 📦 **Cross-Platform:** Designed for Android & iOS.

---

## 🚀 Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  geo_engine_sdk:
    git:
      url: [https://github.com/AlexG695/geo-engine-dart.git](https://github.com/AlexG695/geo-engine-dart.git)
      ref: main
  # Required for initialization bindings
  flutter:
    sdk: flutter

```

Then run:

```bash
flutter pub get

```

---

## ⚡ Basic Usage

### 1️⃣ Initialization (⚠️ Required)

Due to the local storage engine, you **must** initialize the SDK within your `main` function.

```dart
import 'package:flutter/material.dart';
import 'package:geo_engine_sdk/geo_engine_sdk.dart';

void main() async {
  // Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🚀 Initialize the local storage engine (Hive)
  await GeoEngine.initialize();

  runApp(const MyApp());
}

```

### 2️⃣ Create an Instance

```dart
final geo = GeoEngine(
  apiKey: 'sk_live_...',
  debug: true, // Enable logs to visualize buffering and batch syncing
);

```

### 3️⃣ Send Location

The `sendLocation` method is now **network-agnostic**. You don't need to handle connectivity errors:

* **Online:** Sends the data (or adds to the current batch).
* **Offline:** Automatically saves to disk.

```dart
await geo.sendLocation(
  deviceId: 'truck-01',
  latitude: 19.4326,
  longitude: -99.1332,
  // timestamp is optional (defaults to DateTime.now())
);

// No try/catch needed for network errors; the SDK handles resilience.

```

---

## 🔧 Geofence Management

The SDK allows you to create monitoring zones programmatically (useful for admin apps).

```dart
try {
  final zone = await geo.createGeofence(
    name: "Central Warehouse",
    webhookUrl: "[https://my-backend.com/webhook](https://my-backend.com/webhook)",
    coordinates: [
      [19.4, -99.1],
      [19.5, -99.1],
      [19.5, -99.2], // The SDK automatically closes the polygon
    ]
  );
  print('Geofence created: ${zone['id']}');
} catch (e) {
  print('Error creating zone: $e');
}

```

---

## ⚙️ Advanced Configuration

### Development Environments

If you are testing against a local backend (Go + PostGIS in Docker), you can override the default URLs:

```dart
final geo = GeoEngine(
  apiKey: 'sk_test_...',
  ingestUrl: '[http://10.0.2.2:8080](http://10.0.2.2:8080)',      // For Batch Ingestion
  managementUrl: '[http://10.0.2.2:8081](http://10.0.2.2:8081)',  // For Geofence Mgmt
);

```

---

## 📋 Parameters

### `sendLocation`

| Parameter | Type | Description |
| --- | --- | --- |
| deviceId | String | Unique device identifier. |
| latitude | double | GPS Latitude. |
| longitude | double | GPS Longitude. |
| timestamp | int? | (Optional) Unix timestamp. Defaults to `now()`. |

---

## 🛣 Roadmap

* [x] Battery Optimization (Batching)
* [x] Offline Support (Store & Forward)
* [x] Geofence Integration
* [x] Background Location Service (Foreground Service)
* [x] Official release on pub.dev

---

## 🤝 Contributing

Contributions are welcome! 🙌

1. Fork the repository.
2. Create a branch (`feature/offline-mode`).
3. Commit your changes.
4. Open a Pull Request.

---

## 📄 License

MIT License © Geo-Engine
