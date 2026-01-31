# 📱 Geo-Engine Flutter SDK

![Build Status](https://github.com/AlexG695/geo-engine-dart/actions/workflows/flutter_test.yml/badge.svg)

Cliente oficial para integrar **rastreo de ubicación en tiempo real** en aplicaciones Flutter. Permite enviar coordenadas GPS de dispositivos móviles hacia la plataforma **Geo-Engine** de forma sencilla y segura.

---

## ✨ Características

- 📍 Envío de ubicación (latitud / longitud)
- 🔐 Autenticación mediante API Key
- ⚡ API simple y asincrónica
- 🧪 Soporte para entornos locales y de pruebas
- 📦 Diseñado para apps Flutter (Android / iOS)

---

## 🚀 Instalación

Agrega la dependencia en tu archivo `pubspec.yaml`:

```yaml
dependencies:
  geo_engine_sdk:
    git:
      url: https://github.com/AlexG695/geo-engine-dart.git
      ref: main
```

Luego ejecuta:

```bash
flutter pub get
```

> 📝 **Nota**: En el futuro, cuando el paquete esté publicado en **pub.dev**, podrás instalarlo así:
>
> ```yaml
> dependencies:
>   geo_engine_sdk: ^1.0.3
> ```

---

## ⚡ Uso Básico

### 1️⃣ Importar el paquete

```dart
import 'package:geo_engine_sdk/geo_engine_sdk.dart';
```

### 2️⃣ Inicializar el cliente

```dart
final geo = GeoEngine(apiKey: 'sk_live_...');
```

### 3️⃣ Enviar ubicación

```dart
try {
  await geo.sendLocation(
    deviceId: 'camion-01',
    latitude: 19.4326,
    longitude: -99.1332,
  );

  print('Enviado con éxito');
} catch (e) {
  print('Error: $e');
}
```

## 🔒 Security Configuration (Optional but Recommended)

To enable Device Integrity checks (blocking emulators and rooted devices), 
you must provide your Android Cloud Project Number.

### Option A: Via Constructor (Easiest)
Pass your project number when initializing the engine:

```dart
final geo = GeoEngine(
  apiKey: "YOUR_API_KEY",
  androidCloudProjectNumber: "1234567890", // <--- De la Consola de Google Cloud o Consola de Firebase
);
```

---

## 🔧 Configuración Avanzada

### Usar un servidor local o entorno de pruebas

Si necesitas apuntar a un backend local (por ejemplo durante desarrollo), puedes sobrescribir la URL de ingestión:

```dart
final geo = GeoEngine(
  apiKey: 'sk_test_...',
  ingestUrl: 'http://10.0.2.2:8080', // Localhost desde emulador Android
);
```

---

## 📋 Parámetros

### `sendLocation`

| Parámetro   | Tipo   | Descripción |
|------------|--------|-------------|
| deviceId   | String | Identificador único del dispositivo |
| latitude   | double | Latitud GPS |
| longitude  | double | Longitud GPS |

---

## 🚧 Manejo de Errores

Todos los métodos lanzan excepciones en caso de error de red, autenticación o validación. Se recomienda envolver las llamadas en bloques `try / catch`.

---

## 🛣 Roadmap

- ⏱ Envío periódico de ubicación
- 🔋 Optimización para bajo consumo de batería
- 🗺 Integración con geocercas
- 📦 Publicación oficial en pub.dev

---

## 🤝 Contribuir

Las contribuciones son bienvenidas 🙌

1. Haz un fork del repositorio
2. Crea una rama (`feature/nueva-funcionalidad`)
3. Haz commit de tus cambios
4. Abre un Pull Request

---

## 📄 Licencia

MIT License © Geo-Engine

