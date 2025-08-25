import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Service for handling location-related operations including permissions
/// and getting the current position.
class LocationService {
  /// Request location permissions from the user.
  /// Returns true if permission is granted, false otherwise.
  Future<bool> requestLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return false;
    }

    // Check location permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission denied
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permission denied forever
      return false;
    }

    // Permission granted
    return true;
  }

  /// Get the current position of the device.
  /// Returns null if permission is not granted or location cannot be determined.
  Future<LatLng?> getCurrentLocation() async {
    try {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      // Request the most accurate position available within 10 seconds.
      const LocationSettings settings = LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      );

      final Position position =
          await Geolocator.getCurrentPosition(locationSettings: settings);

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      // Handle any errors (e.g., timeout, location unavailable)
      return null;
    }
  }

  /// Start listening to location updates.
  /// Returns a stream of position updates.
  Stream<LatLng> getLocationStream() {
    // Use the highest accuracy and a tighter distance filter so updates are
    // reported more precisely.
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5, // Update every 5 meters
    );

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).map((Position position) => LatLng(position.latitude, position.longitude));
  }

  /// Check if location services are enabled.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}
