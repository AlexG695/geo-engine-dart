# 🛡️ Geo-Engine Flutter SDK

[![pub package](https://img.shields.io/pub/v/geo_engine_sdk.svg)](https://pub.dev/packages/geo_engine_sdk)
![Build Status](https://github.com/AlexG695/geo-engine-dart/actions/workflows/flutter_test.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)


> *Read this in English: [README.md](./README.md)*


**Rastreo de ubicación Seguro, Offline-First y Eficiente en Batería para apps de Flutter de misión crítica.**

Geo-Engine no es simplemente un rastreador de ubicación; es una **capa de garantía de telemetría**. Asegura que las coordenadas que recibes provienen de un dispositivo físico real, rechazando Ubicaciones Simuladas (Mock Locations), Emuladores y Granjas de Bots mediante evidencia criptográfica.

Diseñado para **Logística, Fintech y Gestión de Fuerza de Trabajo**.

---

## 🔥 ¿Por qué Geo-Engine?

| Característica | Descripción |
| --- | --- |
| 🛡️ **Anti-Spoofing** | Integración nativa con **Google Play Integrity** (Android) y **Apple DeviceCheck** (iOS) para verificar la autenticidad del dispositivo. |
| ✈️ **Offline-First** | Resiliencia de grado militar. Los datos se persisten localmente (Hive) cuando no hay red y se sincronizan automáticamente al volver la conexión. |
| 🔋 **Batería Inteligente** | Utiliza procesamiento por lotes (batching) inteligente para minimizar el uso del radio, ahorrando hasta un 40% de batería comparado con el streaming tradicional. |
| 🚀 **Integración Rápida** | Obtén rastreo de nivel empresarial con solo 5 líneas de código. |

---

## 🚀 Instalación

Agrega el paquete oficial desde pub.dev:

```bash
flutter pub add geo_engine_sdk

```

---

## ⚡ Inicio Rápido

### 1️⃣ Inicialización

Inicializa el motor de almacenamiento dentro de tu función `main()`.

```dart
import 'package:geo_engine_sdk/geo_engine_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🚀 Inicializar el motor offline-first
  await GeoEngine.initialize();

  runApp(const MyApp());
}

```

### 2️⃣ Configuración (Con Seguridad)

Para activar el escudo **Anti-Fraude**, debes proporcionar el Número de Proyecto de Google Cloud.

```dart
final geo = GeoEngine(
  apiKey: 'sk_live_...',
  // 🛡️ SEGURIDAD HABILITADA:
  // Esto activa Play Integrity (Android) y DeviceCheck (iOS)
  androidCloudProjectNumber: '1234567890', 
  debug: true, 
);

```

---

## 🔒 Configuración de Seguridad (Anti-Fraude)

Para habilitar el **Escudo de Integridad del Dispositivo** (que bloquea emuladores, dispositivos rooteados y GPS spoofing), es obligatorio configurar el `androidCloudProjectNumber`.

### ¿Qué Número de Proyecto debo usar?

Depende de tu backend:

| Escenario | Número de Proyecto a Usar |
| --- | --- |
| **A. Usando Geo Engine Cloud (SaaS)** | Usa nuestro ID oficial: **`939798381003`** |
| **B. Backend Auto-alojado (Self-Hosted)** | Usa tu **propio** Número de Proyecto de Google Cloud. |

### Implementación

Pasa el número en el constructor. Esto le indica a Google que debe encriptar el token de integridad específicamente para el backend verificador.

```dart
final geo = GeoEngine(
  apiKey: "TU_API_KEY",
  
  // 🛡️ CONFIGURACIÓN DE SEGURIDAD
  // Esto habilita Play Integrity (Android) y DeviceCheck (iOS)
  // ---------------------------------------------------------
  // Opción A: Usando la nube oficial de Geo Engine
  androidCloudProjectNumber: "939798381003", 
  
  // Opción B: Infraestructura Propia (Usa tu propio Project ID)
  // androidCloudProjectNumber: "TU_PROPIO_PROJECT_NUMBER",
);

```

> **Nota:** Si se omite este parámetro, el SDK funcionará en "Modo No Verificado", y el backend podría rechazar los datos dependiendo de tus políticas de seguridad.

### 3️⃣ Enviar Ubicación Verificada

El SDK maneja la conectividad, el almacenamiento en búfer y los encabezados de seguridad automáticamente.

```dart
await geo.sendLocation(
  deviceId: 'camion-042',
  latitude: 19.4326,
  longitude: -99.1332,
);

// ✅ Resultado:
// - Si está Online: Se envía inmediatamente con el Token de Integridad.
// - Si está Offline: Se encripta y guarda en disco. Se envía automáticamente después.

```

---

## 🛡️ ¿Cómo funciona la Seguridad?

Cuando envías una ubicación, Geo-Engine hace más que solo reenviar coordenadas:

1. **Desafío (Challenge):** Contacta al enclave seguro de hardware (TEE) del dispositivo.
2. **Atestación (Attest):** Solicita una prueba criptográfica de que el dispositivo es genuino, no modificado y no es un emulador.
3. **Verificación (Verify):** Este token se adjunta a la carga útil (payload). Tu backend (o Geo-Engine Cloud) lo verifica directamente con los servidores de Apple/Google.

**Resultado:** Dejas de pagar por viajes falsos y asistencias simuladas.

---

## 🔧 Gestión de Geocercas (Geofences)

Crea zonas de monitoreo dinámicas programáticamente:

```dart
final zone = await geo.createGeofence(
  name: "Almacén Central",
  webhookUrl: "https://api.logistica.com/webhooks/entrada",
  coordinates: [
    [19.4, -99.1],
    [19.5, -99.1],
    [19.5, -99.2], 
  ]
);

```

---

## 🛣 Roadmap y Soporte

* [x] Almacenamiento Offline (Store & Forward)
* [x] **v1.0:** Optimización de Batería (Batching)
* [x] **v1.1:** Integridad de Dispositivo Nativa (Anti-Fraude)
* [ ] v1.2: Detección de Actividad y Movimiento (Quieto/Caminando/Conduciendo)

**¿Necesitas ayuda con la integración?** Abre un issue o contacta a los mantenedores.

---

## 📄 Licencia

MIT License © Geo-Engine