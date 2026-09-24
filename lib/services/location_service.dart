import 'package:geolocator/geolocator.dart';

class LocationResult {
  final Position? position;
  final bool isPermissionGranted;
  final String? errorMessage;

  const LocationResult({
    this.position,
    required this.isPermissionGranted,
    this.errorMessage,
  });
}

enum LocationStatus {
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationService {
  static const double defaultLatitude = 12.9716; // Bengaluru fallback
  static const double defaultLongitude = 77.5946;

  static Future<LocationStatus> checkPermissionStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationStatus.serviceDisabled;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationStatus.permissionDenied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationStatus.permissionDeniedForever;
      }

      return LocationStatus.ready;
    } catch (_) {
      return LocationStatus.permissionDenied;
    }
  }

  static Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          isPermissionGranted: false,
          errorMessage: 'Location services are disabled. Please enable GPS in device settings.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            isPermissionGranted: false,
            errorMessage: 'Location permission denied. Please grant permission to share ride updates.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          isPermissionGranted: false,
          errorMessage: 'Location permission permanently denied. Please enable in app settings.',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      return LocationResult(position: pos, isPermissionGranted: true);
    } catch (e) {
      return LocationResult(position: null, isPermissionGranted: false, errorMessage: e.toString());
    }
  }

  /// Live GPS position stream throttled by distance and time to conserve battery & network
  static Stream<Position> getPositionStream({int distanceFilter = 10}) {
    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}
