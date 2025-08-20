import 'package:flutter/material.dart';
import '../models/restroom.dart';
import '../services/api_service.dart';

/// Provider responsible for loading and storing the list of [Restroom]
/// objects from the backend. It maintains a busy flag to signal when a
/// network request is in progress. Consumers can listen to this provider
/// to rebuild when new data is available.
class RestroomProvider with ChangeNotifier {
  final ApiService _api;
  List<Restroom> _restrooms = [];
  bool _isLoading = false;

  RestroomProvider(this._api);

  List<Restroom> get restrooms => _restrooms;
  bool get isLoading => _isLoading;

  /// Loads the restroom list from the backend. If a request is already in
  /// flight this method returns early. The new list of restrooms will be
  /// stored and listeners notified on success. Exceptions are propagated.
  Future<void> loadRestrooms() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _restrooms = await _api.fetchRestrooms();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}