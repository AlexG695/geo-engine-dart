import 'dart:async';
import 'package:geolocator/geolocator.dart';

enum TrackingProfile { highAccuracy, balanced, lowPower }

class AdaptiveLocationTracker {
  StreamSubscription<Position>? _positionSubscription;

  Future<void> startTracking({
    required TrackingProfile profile,
    required Function(Position position) onPositionReceived,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Los servicios de ubicación están desactivados.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permisos de ubicación denegados.');
      }
    }

    final locationSettings = _getSettingsForProfile(profile);

    await stopTracking();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      onPositionReceived(position);
    });
  }

  LocationSettings _getSettingsForProfile(TrackingProfile profile) {
    switch (profile) {
      case TrackingProfile.highAccuracy:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          intervalDuration: const Duration(seconds: 5),
          forceLocationManager: false,
        );
      case TrackingProfile.balanced:
        return AndroidSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 30,
          intervalDuration: const Duration(seconds: 15),
        );
      case TrackingProfile.lowPower:
        return AndroidSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 100,
          intervalDuration: const Duration(seconds: 60),
        );
    }
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
