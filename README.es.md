# 🛡️ GeoEngine Flutter SDK

[![pub package](https://img.shields.io/pub/v/geo_engine_sdk.svg)](https://pub.dev/packages/geo_engine_sdk)
![Build Status](https://github.com/AlexG695/geo-engine-dart/actions/workflows/flutter_test.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

> *Leer este documento en inglés: [README.md](./README.md)*

**Telemetría de ubicación Zero-Trust, basada en gRPC, Offline-First y Eficiente en Batería para aplicaciones Flutter de misión crítica.**

GeoEngine no es un simple rastreador GPS; es una **capa de garantía de telemetría** diseñada para arquitecturas serverless sobre **GCP Cloud Run**. Garantiza que las coordenadas provengan de un dispositivo físico real, rechazando Ubicaciones Simuladas (Mock Locations), Emuladores y GPS Spoofing mediante evidencia criptográfica nativa.

Diseñado para **Logística, Ambulancias, Rastreo de Flotas y Telemetría Operativa**.

---

## 🔥 Caracteristicas Principales

| Característica | Descripción |
| :--- | :--- |
| ⚡ **gRPC & Protobuf** | Serialización binaria ultra-compacta sobre HTTP/2 que reduce el consumo de datos móviles hasta un 70%. |
| 🛡️ **Anti-Spoofing** | Integración nativa con **Google Play Integrity** (Android) y **Apple DeviceCheck / App Attest** (iOS). |
| ✈️ **Offline-First** | Búfer local persistente (Hive) que encola pings sin conexión y los envía en lote (Batch gRPC) al recuperar cobertura. |
| 🔋 **Batería Inteligente** | Filtros de distancia dinámicos que minimizan el encendido del módem celular. |
| ☁️ **Optimizado para Cloud Run** | Invocaciones Unarias gRPC stateless que evitan desconexiones de sockets y permiten auto-escalado a cero. |

---

## 🚀 Instalación

Agrega el paquete oficial desde pub.dev:

```bash
flutter pub add geo_engine_sdk

```

---

## ⚡ Inicio Rápido

### 1️⃣ Inicialización

Inicializa el motor de almacenamiento local en tu función `main()` antes de arrancar la aplicación:

```dart
import 'package:flutter/material.dart';
import 'package:geo_engine_sdk/geo_engine_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🚀 Inicializar el almacenamiento local persistente
  await GeoEngine.initialize();

  runApp(const MyApp());
}

```

### 2️⃣ Configuración

Instancia el cliente `GeoEngine` configurando las credenciales de tu proyecto y el host gRPC de ingestión:

```dart
final geo = GeoEngine(
  apiKey: 'sk_live_tu_api_key',
  grpcHost: 'grpc.ingest.geoengine.dev', // Host de ingestión gRPC en Cloud Run
  grpcPort: 443,
  managementUrl: '[https://api.geoengine.dev](https://api.geoengine.dev)',
  
  // 🛡️ SEGURIDAD HABILITADA:
  // Activa Play Integrity (Android) y App Attest (iOS)
  androidCloudProjectNumber: '123456789012', 
  debug: kDebugMode, 
);

```

### 3️⃣ Enviar Ubicación Verificada

El SDK gestiona de forma automática la conectividad, el token de sesión JWT y la transmisión gRPC:

```dart
await geo.sendLocation(
  deviceId: 'operador-042',
  latitude: 19.4326,
  longitude: -99.1332,
  accuracy: 4.5,
  speed: 12.0,
  heading: 180.0,
  isMocked: false,
);

// ✅ Flujo de Ejecución:
// - Si hay red: Envío inmediato por gRPC Unary adjuntando el JWT validado.
// - Si está Offline: Se guarda en disco (Hive) -> Se envía en lote automáticamente al reconectarse.

```

---

## 🔒 Configuración de Seguridad (Anti-Fraude)

Para habilitar el **Escudo de Integridad de Dispositivo** (bloqueando emuladores, dispositivos rooteados y GPS falso), configura el `androidCloudProjectNumber`.

### ¿Qué Número de Proyecto debo usar?

| Escenario | Número de Proyecto a Usar |
| --- | --- |
| **A. Usando GeoEngine Cloud (SaaS)** | Usa nuestro ID oficial: **`939798381003`** |
| **B. Infraestructura Propia (Self-Hosted)** | Usa tu **propio** Número de Proyecto de Google Cloud. |

```dart
final geo = GeoEngine(
  apiKey: "TU_API_KEY",
  grpcHost: "grpc.ingest.geoengine.dev",
  
  // 🛡️ CONFIGURACIÓN DE SEGURIDAD
  // Opción A: Nube SaaS Oficial
  androidCloudProjectNumber: "939798381003", 
  
  // Opción B: Servidor Propio
  // androidCloudProjectNumber: "TU_PROPIO_PROJECT_NUMBER",
);

```

---

## 🛡️ Cómo Funciona la Seguridad Zero-Trust

1. **Desafío Nonce:** El SDK solicita un nonce criptográfico de un solo uso al backend.
2. **Atestación de Hardware:** El sistema operativo solicita pruebas al enclave seguro (TEE) de que el dispositivo no ha sido alterado.
3. **Verificación de Sesión:** El backend valida la firma con Google/Apple y emite un token JWT temporal.
4. **Ingestión de Baja Latencia:** Los pings se transmiten sobre gRPC adjuntando el JWT en las cabeceras, manteniendo alta velocidad y seguridad.

---

## 📄 Licencia

MIT License © GeoEngine

