import 'package:flutter/material.dart';
import '../models/restroom.dart';
import '../services/api_service.dart';

/// Provider responsible for loading and storing the list of [Restroom]
/// objects from the backend. It maintains a busy flag to signal when a
/// network request is in progress. Falls back to demo data if the backend
/// is unreachable.
class RestroomProvider with ChangeNotifier {
  final ApiService _api;
  List<Restroom> _restrooms = [];
  bool _isLoading = false;

  RestroomProvider(this._api);

  List<Restroom> get restrooms => _restrooms;
  bool get isLoading => _isLoading;

  /// Loads the restroom list from the backend. Falls back to built-in
  /// demo data if the API is unreachable (e.g. backend not deployed).
  Future<void> loadRestrooms() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _restrooms = await _api.fetchRestrooms();
    } catch (_) {
      // Backend unavailable — use demo data so the app is still usable
      _restrooms = _demoRestrooms;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

/// Realistic CMU campus restrooms for demo/offline mode.
final List<Restroom> _demoRestrooms = [
  const Restroom(
    id: 'demo-1',
    name: '1st Floor Men\'s',
    building: 'Gates Hillman Center',
    latitude: 40.4434,
    longitude: -79.9446,
    generalRating: 4.2,
    sinkRating: 3.8,
    floor: 1,
    description: 'Main floor restroom near the café. Usually clean, good soap dispensers.',
  ),
  const Restroom(
    id: 'demo-2',
    name: '3rd Floor Women\'s',
    building: 'Gates Hillman Center',
    latitude: 40.4436,
    longitude: -79.9448,
    generalRating: 4.5,
    sinkRating: 4.3,
    floor: 3,
    description: 'Quiet floor, less traffic. Well-maintained with paper towels.',
  ),
  const Restroom(
    id: 'demo-3',
    name: 'Basement Restroom',
    building: 'Wean Hall',
    latitude: 40.4427,
    longitude: -79.9455,
    generalRating: 3.1,
    sinkRating: 2.9,
    floor: 0,
    description: 'Basement level. Functional but older fixtures. Can be noisy from pipes.',
  ),
  const Restroom(
    id: 'demo-4',
    name: '2nd Floor Restroom',
    building: 'Wean Hall',
    latitude: 40.4429,
    longitude: -79.9453,
    generalRating: 3.6,
    sinkRating: 3.4,
    floor: 2,
    description: 'Near the main lecture halls. Gets busy between classes.',
  ),
  const Restroom(
    id: 'demo-5',
    name: 'Main Floor',
    building: 'Tepper School of Business',
    latitude: 40.4415,
    longitude: -79.9422,
    generalRating: 4.7,
    sinkRating: 4.6,
    floor: 1,
    description: 'Recently renovated. Touchless fixtures, excellent maintenance.',
  ),
  const Restroom(
    id: 'demo-6',
    name: '1st Floor',
    building: 'Hunt Library',
    latitude: 40.4413,
    longitude: -79.9436,
    generalRating: 4.0,
    sinkRating: 3.7,
    floor: 1,
    description: 'Near the entrance. Popular spot, cleaned frequently.',
  ),
  const Restroom(
    id: 'demo-7',
    name: '4th Floor Quiet',
    building: 'Hunt Library',
    latitude: 40.4414,
    longitude: -79.9438,
    generalRating: 4.4,
    sinkRating: 4.1,
    floor: 4,
    description: 'Top floor study area restroom. Very quiet, rarely crowded.',
  ),
  const Restroom(
    id: 'demo-8',
    name: 'Ground Floor',
    building: 'University Center',
    latitude: 40.4432,
    longitude: -79.9424,
    generalRating: 3.4,
    sinkRating: 3.2,
    floor: 1,
    description: 'High traffic area near dining. Gets messy during lunch rush.',
  ),
  const Restroom(
    id: 'demo-9',
    name: '2nd Floor',
    building: 'University Center',
    latitude: 40.4433,
    longitude: -79.9426,
    generalRating: 3.9,
    sinkRating: 3.6,
    floor: 2,
    description: 'Near the game room. Less crowded than ground floor.',
  ),
  const Restroom(
    id: 'demo-10',
    name: '1st Floor Men\'s',
    building: 'Baker Hall',
    latitude: 40.4413,
    longitude: -79.9462,
    generalRating: 3.3,
    sinkRating: 3.0,
    floor: 1,
    description: 'Older building. Functional but due for renovation.',
  ),
  const Restroom(
    id: 'demo-11',
    name: 'Lobby Restroom',
    building: 'Purnell Center for the Arts',
    latitude: 40.4430,
    longitude: -79.9430,
    generalRating: 4.1,
    sinkRating: 3.9,
    floor: 1,
    description: 'Theater lobby restroom. Clean, well-lit, good mirrors.',
  ),
  const Restroom(
    id: 'demo-12',
    name: '2nd Floor',
    building: 'Hamerschlag Hall',
    latitude: 40.4423,
    longitude: -79.9462,
    generalRating: 3.5,
    sinkRating: 3.3,
    floor: 2,
    description: 'Engineering building. Basic but reliable.',
  ),
];
