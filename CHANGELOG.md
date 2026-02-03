# CHANGELOG

## [1.1.14] - 2026-02-03

*  **Platform Awareness:** Added conditional logic to strictly separate Android Play Integrity tokens from iOS requests using the `X-Platform` header.

## [1.1.13] - 2026-02-03

*  **Platform Awareness:** Added conditional logic to strictly separate Android Play Integrity tokens from iOS requests using the `X-Platform` header.

## [1.1.12] - 2026-02-02

* 📚 **Documentation Fix:** Clarified `GeoEngine` instantiation usage in documentation comments.
* 🐛 **Example Update:** Fixed `main.dart` in the example app to correctly implement `GeoEngine.initialize()`

## [1.1.11] - 2026-02-02

* 🐛 **Cross-Platform Fix:** Fixed an issue where iOS clients were sending Android-specific integrity headers.
* 📱 **Platform Awareness:** Added conditional logic to strictly separate Android Play Integrity tokens from iOS requests using the `X-Platform` header.

## [1.1.10] - 2026-02-02

* 📝 **Documentation Overhaul:** Completely redesigned README with a focus on Anti-Fraud features and Security.
* 🌐 **Localization:** Added Spanish documentation (`README.es.md`).
* 🛡️ **Security Guide:** Added clear guidelines on how to configure `androidCloudProjectNumber` for SaaS vs Self-Hosted environments.
* ⚡ **UX:** Improved installation and quick start examples.

## [1.1.9] - 2026-02-01

### Fixed
- **Android Context:** Se corrigió el error de que el Context de Android no fuera pasado al plugin.

## [1.1.8] - 2026-02-01

### Fixed
- **Android Context:** Se corrigió el error de que el Context de Android no fuera pasado al plugin.

## [1.1.7] - 2026-02-01

### Fixed
- **Bug fix:** Bug fix en la sincronización de datos con el servidor.

## [1.1.6] - 2026-01-31

### Added
- **Security:** Implementación de Device Integrity checks para validar la autenticidad del dispositivo.
- **Security:** Configuración de `androidCloudProjectNumber` para permitir la verificación de integridad en Android.
- **Security:** Manejo de errores 403 para invalidar tokens de integridad en caso de detección de fraude.

### Changed
- **Dependency Injection:** El constructor de `GeoEngine` ahora acepta `androidCloudProjectNumber` como parámetro opcional.
- **Documentation:** Actualización de `README.md` y `README.es.md` con instrucciones de configuración de seguridad.

### Fixed
- **Buffer Flushing:** Solucionado un error donde los datos guardados en el buffer local no se eliminaban correctamente después de recibir un `200 OK` del servidor.

## [1.1.5] - 2026-01-31

### Added
- **CI/CD:** Configuración de GitHub Actions para ejecutar pruebas unitarias y verificar formato automáticamente en cada push y PR.
- **Tests:** Suite completa de pruebas unitarias para `GeoEngine`.
  - Simulación de escenarios offline (guardado en buffer Hive).
  - Verificación de acumulación de datos (batching).
  - Validación de sincronización exitosa con el servidor.
- **Mocks:** Implementación de mocks para `path_provider` y `connectivity_plus` para entornos de prueba.

### Changed
- **Dependency Injection:** El constructor de `GeoEngine` ahora acepta un `http.Client` opcional para facilitar el testing y mocking de peticiones HTTP.

### Fixed
- **Buffer Flushing:** Solucionado un error donde los datos guardados en el buffer local no se eliminaban correctamente después de recibir un `200 OK` del servidor.
- **Formatting:** Aplicado `dart format` a todo el proyecto para cumplir con los estándares de estilo de Dart.

## [1.1.4] - 2026-01-31

### Added
- **Security:** Implementación de Device Integrity checks para validar la autenticidad del dispositivo.
- **Security:** Configuración de `androidCloudProjectNumber` para permitir la verificación de integridad en Android.
- **Security:** Manejo de errores 403 para invalidar tokens de integridad en caso de detección de fraude.

### Changed
- **Dependency Injection:** El constructor de `GeoEngine` ahora acepta `androidCloudProjectNumber` como parámetro opcional.
- **Documentation:** Actualización de `README.md` y `README.es.md` con instrucciones de configuración de seguridad.

### Fixed
- **Buffer Flushing:** Solucionado un error donde los datos guardados en el buffer local no se eliminaban correctamente después de recibir un `200 OK` del servidor.

## [1.1.3] - 2026-01-29

### Added
- **CI/CD:** Configuración de GitHub Actions para ejecutar pruebas unitarias y verificar formato automáticamente en cada push y PR.
- **Tests:** Suite completa de pruebas unitarias para `GeoEngine`.
  - Simulación de escenarios offline (guardado en buffer Hive).
  - Verificación de acumulación de datos (batching).
  - Validación de sincronización exitosa con el servidor.
- **Mocks:** Implementación de mocks para `path_provider` y `connectivity_plus` para entornos de prueba.

### Changed
- **Dependency Injection:** El constructor de `GeoEngine` ahora acepta un `http.Client` opcional para facilitar el testing y mocking de peticiones HTTP.

### Fixed
- **Buffer Flushing:** Solucionado un error donde los datos guardados en el buffer local no se eliminaban correctamente después de recibir un `200 OK` del servidor.
- **Formatting:** Aplicado `dart format` a todo el proyecto para cumplir con los estándares de estilo de Dart.

## [1.0.3] - 2026-01-26

Corrección de URL de ingestión.

## [1.0.2] - 2026-01-16

Corrección de URL de ingestión.

## [1.0.1] - 2026-01-02

Corrección de URL de ingestión.

## [1.0.0] - 2025-12-31

Lanzamiento inicial del SDK de Geo-Engine.

Soporte para envío de ubicación en tiempo real.

Creación programática de geocercas.