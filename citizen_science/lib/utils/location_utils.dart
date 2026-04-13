import 'package:geolocator/geolocator.dart';

/// Result of a location permission check or request.
class LocationResult {
  /// Whether the location was successfully obtained.
  final bool success;

  /// The position if successful, null otherwise.
  final Position? position;

  /// Error message if unsuccessful, null otherwise.
  final String? errorMessage;

  const LocationResult({
    required this.success,
    this.position,
    this.errorMessage,
  });
}

/// Utility class for handling location permissions and retrieval.
class LocationUtils {
  /// Checks and requests location permissions, then retrieves the current position.
  ///
  /// Returns a [LocationResult] containing the position if successful,
  /// or an error message if unsuccessful.
  static Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          success: false,
          errorMessage: 'Servizi di localizzazione disabilitati',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            success: false,
            errorMessage: 'Permesso di localizzazione negato',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          success: false,
          errorMessage: 'Permesso di localizzazione negato permanentemente',
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LocationResult(success: true, position: position);
    } catch (e) {
      return LocationResult(
        success: false,
        errorMessage: 'Errore nel recupero della posizione: $e',
      );
    }
  }
}
