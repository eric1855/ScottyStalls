import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

/// Provider that manages the user's current location and location permissions.
/// It provides a stream of location updates and maintains the current position.
class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  LatLng? _currentLocation;
  bool _hasPermission = false;
  bool _isLocationServiceEnabled = false;
  bool _isLoading = false;
  bool _isRequestingPermission = false;
  StreamSubscription<LatLng>? _locationSubscription;

  LatLng? get currentLocation => _currentLocation;
  bool get hasPermission => _hasPermission;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get isLoading => _isLoading;

  /// Initialize the location provider by checking permissions and services.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLocationServiceEnabled = await _locationService.isLocationServiceEnabled();
      if (_isLocationServiceEnabled) {
        _hasPermission = await _locationService.requestLocationPermission();
        if (_hasPermission) {
          // Get initial location
          _currentLocation = await _locationService.getCurrentLocation();
          
          // Start listening to location updates
          _startLocationStream();
        }
      }
    } catch (e) {
      // Handle any errors
      debugPrint('Error initializing location: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start listening to location updates from the stream.
  void _startLocationStream() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.getLocationStream().listen(
      (LatLng newLocation) {
        _currentLocation = newLocation;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  /// Manually refresh the current location.
  Future<void> refreshLocation() async {
    if (!_hasPermission || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentLocation = await _locationService.getCurrentLocation();
    } catch (e) {
      debugPrint('Error refreshing location: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Request location permission again (useful if user denied initially).
  Future<void> requestPermission() async {
    if (_isRequestingPermission) return;

    _isRequestingPermission = true;
    _hasPermission = await _locationService.requestLocationPermission();
    if (_hasPermission) {
      await refreshLocation();
      _startLocationStream();
    }
    _isRequestingPermission = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
