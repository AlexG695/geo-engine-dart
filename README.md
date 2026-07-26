# 🛡️ GeoEngine Flutter SDK

[![pub package](https://img.shields.io/pub/v/geo_engine_sdk.svg)](https://pub.dev/packages/geo_engine_sdk)
![Build Status](https://github.com/AlexG695/geo-engine-dart/actions/workflows/flutter_test.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

> *Read this in Spanish: [README.es.md](./README.es.md)*

**Zero-Trust, gRPC-powered, Offline-First, and Battery-Efficient location telemetry for mission-critical Flutter apps.**

GeoEngine is a **telemetry assurance layer** designed for serverless architectures (GCP Cloud Run). It guarantees that coordinates received come from a real physical device by validating hardware attestation, rejecting Mock Locations, Emulators, and GPS Spoofing through cryptographic evidence.

Designed for **Logistics, Ambulances, Fleet Tracking, and Workforce Telemetry**.

---

## 🔥 Key Features

| Feature | Description |
| :--- | :--- |
| ⚡ **gRPC & Protobuf** | Ultra-compact binary serialization over HTTP/2 reduces mobile data overhead by up to 70%. |
| 🛡️ **Anti-Spoofing** | Native integration with **Google Play Integrity** (Android) & **Apple DeviceCheck / App Attest** (iOS). |
| ✈️ **Offline-First** | Automatic persistent FIFO storage (Hive) queues coordinates offline and flushes via gRPC Batch upon connection recovery. |
| 🔋 **Battery Smart** | Dynamic distance filtering minimizes radio wake-ups, saving battery power. |
| ☁️ **Cloud Run Ready** | Stateless Unary gRPC calls prevent socket connection drops and support seamless auto-scaling. |

---

## 🚀 Installation

Add the official package from pub.dev:

```bash
flutter pub add geo_engine_sdk

```

---

## ⚡ Quick Start

### 1️⃣ Initialization

Initialize the Hive persistent storage engine inside your `main()` entry point before running the app:

```dart
import 'package:flutter/material.dart';
import 'package:geo_engine_sdk/geo_engine_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🚀 Initialize the offline-first persistent engine
  await GeoEngine.initialize();

  runApp(const MyApp());
}

```

### 2️⃣ Configuration

Construct the `GeoEngine` client with your project credentials and gRPC ingestion endpoint:

```dart
final geo = GeoEngine(
  apiKey: 'sk_live_your_api_key',
  grpcHost: 'grpc.ingest.geoengine.dev', // GeoEngine Cloud Run Ingestion Host
  grpcPort: 443,
  managementUrl: '[https://api.geoengine.dev](https://api.geoengine.dev)',
  
  // 🛡️ SECURITY ENABLED:
  // Enables Google Play Integrity (Android) & App Attest (iOS)
  androidCloudProjectNumber: '123456789012', 
  debug: kDebugMode, 
);

```

### 3️⃣ Send Verified Location Pings

The SDK manages connectivity, challenge-verify token generation, and gRPC transmission automatically:

```dart
await geo.sendLocation(
  deviceId: 'driver-042',
  latitude: 19.4326,
  longitude: -99.1332,
  accuracy: 4.5,
  speed: 12.0,
  heading: 180.0,
  isMocked: false,
);

// ✅ Execution Pipeline:
// - If Online: Sent immediately via gRPC Unary with verified Session JWT.
// - If Offline: Persisted to disk (Hive) -> Auto-flushed in Batch upon reconnection.

```

---

## 🔒 Security Configuration (Anti-Fraud)

To enable the **Device Integrity Shield** (blocking emulators, rooted devices, and GPS spoofing), provide your `androidCloudProjectNumber`.

### Which Project Number should I use?

| Scenario | Project Number to Use |
| --- | --- |
| **A. Using GeoEngine Cloud (SaaS)** | Use our official SaaS ID: **`939798381003`** |
| **B. Self-Hosted Infrastructure** | Use your **own** Google Cloud Project Number. |

```dart
final geo = GeoEngine(
  apiKey: "YOUR_API_KEY",
  grpcHost: "grpc.ingest.geoengine.dev",
  
  // 🛡️ SECURITY CONFIGURATION
  // Option A: SaaS Nube Oficial
  androidCloudProjectNumber: "939798381003", 
  
  // Option B: Self-Hosted Infrastructure
  // androidCloudProjectNumber: "YOUR_OWN_PROJECT_NUMBER",
);

```

---

## 🛡️ How Zero-Trust Security Works

1. **Challenge Nonce:** The SDK requests a single-use cryptographic nonce from the backend.
2. **Hardware Attestation:** The native OS requests proof from the hardware enclave (TEE) that the device is untampered.
3. **Session Verification:** The backend verifies the token directly with Google/Apple servers and issues a short-lived JWT.
4. **Low-Latency Ingestion:** Location pings are transmitted over gRPC using the JWT in headers, maintaining zero-latency and high security.

---

## 📄 License

MIT License © GeoEngine
