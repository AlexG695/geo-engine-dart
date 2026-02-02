# 🛡️ Geo-Engine Flutter SDK

[![pub package](https://img.shields.io/pub/v/geo_engine_sdk.svg)](https://pub.dev/packages/geo_engine_sdk)
![Build Status](https://github.com/AlexG695/geo-engine-dart/actions/workflows/flutter_test.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**Secure, Offline-First, and Battery-Efficient location tracking for mission-critical Flutter apps.**

Geo-Engine is not just a location tracker; it is a **telemetry assurance layer**. It guarantees that the coordinates you receive come from a real physical device, rejecting Mock Locations, Emulators, and Bot Farms using cryptographic evidence.

Designed for **Logistics, Fintech, and Workforce Management**.

---

## 🔥 Why Geo-Engine?

| Feature | Description |
| :--- | :--- |
| 🛡️ **Anti-Spoofing** | Native integration with **Google Play Integrity** (Android) and **Apple DeviceCheck** (iOS) to verify device authenticity. |
| ✈️ **Offline-First** | Military-grade resilience. Data is persisted locally (Hive) when offline and auto-synced when the network returns. |
| 🔋 **Battery Smart** | Uses intelligent batching to minimize radio wake-ups, saving up to 40% battery compared to raw streaming. |
| 🚀 **Drop-in Ready** | Get enterprise-grade tracking with just 5 lines of code. |

---

## 🚀 Installation

Add the official package from pub.dev:

```bash
flutter pub add geo_engine_sdk

```

---

## ⚡ Quick Start

### 1️⃣ Initialization

Initialize the storage engine in your `main()` function.

```dart
import 'package:geo_engine_sdk/geo_engine_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🚀 Initialize the offline-first engine
  await GeoEngine.initialize();

  runApp(const MyApp());
}

```

### 2️⃣ Configuration (With Security)

To enable the **Anti-Fraud** shield, provide your Google Cloud Project Number.

```dart
final geo = GeoEngine(
  apiKey: 'sk_live_...',
  // 🛡️ SECURITY ENABLED:
  // This enables Play Integrity (Android) & DeviceCheck (iOS)
  androidCloudProjectNumber: '1234567890', 
  debug: true, 
);

```

### 3️⃣ Send Verified Location

The SDK handles connectivity, buffering, and security headers automatically.

```dart
await geo.sendLocation(
  deviceId: 'driver-042',
  latitude: 19.4326,
  longitude: -99.1332,
);

// ✅ Result:
// - If Online: Sent immediately with Integrity Token.
// - If Offline: Encrypted & saved to disk. Auto-flushed later.

```

---

## 🛡️ How the Security Works

When you send a location, Geo-Engine does more than just forward coordinates:

1. **Challenge:** It contacts the device's secure hardware enclave (TEE).
2. **Attest:** It requests a cryptographic proof that the device is genuine, unmodified, and not an emulator.
3. **Verify:** This token is attached to the payload. Your backend (or Geo-Engine Cloud) verifies it directly with Apple/Google servers.

**Outcome:** You stop paying for fake trips and spoofed attendance.

---

## 🔧 Geofence Management

Create dynamic monitoring zones programmatically:

```dart
final zone = await geo.createGeofence(
  name: "Central Warehouse",
  webhookUrl: "[https://api.logistics.com/webhooks/entry](https://api.logistics.com/webhooks/entry)",
  coordinates: [
    [19.4, -99.1],
    [19.5, -99.1],
    [19.5, -99.2], 
  ]
);

```

---

## 🛣 Roadmap & Support

* [x] Offline Store & Forward
* [x] **v1.0:** Battery Optimization (Batching)
* [x] **v1.1:** Native Device Integrity (Anti-Fraud)
* [ ] v1.2: Motion Activity Detection (Still/Walking/Driving)

**Need help integration?** Open an issue or contact the maintainers.

---

## 📄 License

MIT License © Geo-Engine
