/// A simple data model representing a restroom on campus.
///
/// Each restroom has a name, the building it belongs to, a latitude and
/// longitude for mapping, and current aggregate ratings for the general
/// facilities and the sink area. Additional fields (such as distance from
/// the user) can be computed dynamically at runtime.
class Restroom {
  final String id;
  final String name;
  final String building;
  final double latitude;
  final double longitude;
  final double generalRating;
  final double sinkRating;

  const Restroom({
    required this.id,
    required this.name,
    required this.building,
    required this.latitude,
    required this.longitude,
    this.generalRating = 4.5,
    this.sinkRating = 4.0,
  });

  // Robust JSON parser: handles num or String for numbers/ids
  factory Restroom.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return Restroom(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '') as String,
      building: (json['building'] ?? '') as String,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      generalRating: _toDouble(json['generalRating']),
      sinkRating: _toDouble(json['sinkRating']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'building': building,
    'latitude': latitude,
    'longitude': longitude,
    'generalRating': generalRating,
    'sinkRating': sinkRating,
  };
}
