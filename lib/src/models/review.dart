/// A model representing a review for a restroom.
///
/// Reviews contain ratings for both the general bathroom area and the sink.
/// Each rating is on a 1–5 scale. A free‑text comment may also be supplied.
/// The `username` is included so that the UI can display who left the
/// review without having to perform another lookup. The `createdAt`
/// timestamp is returned by the backend when the review was recorded.
class Review {
  final String id;
  final String restroomId;
  final String userId;
  final String username;
  final int generalCleanliness;
  final int generalNoise;
  final int generalShittable;
  final int sinkCleanliness;
  final int sinkNoise;
  final int sinkShittable;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.restroomId,
    required this.userId,
    required this.username,
    required this.generalCleanliness,
    required this.generalNoise,
    required this.generalShittable,
    required this.sinkCleanliness,
    required this.sinkNoise,
    required this.sinkShittable,
    required this.comment,
    required this.createdAt,
  });

  /// Creates a Review object from a JSON map returned by the backend. The
  /// backend returns timestamps as ISO8601 strings, which are parsed into
  /// DateTime instances.
  factory Review.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Review(
      id: json['id']?.toString() ?? '',
      restroomId: json['restroomId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      generalCleanliness: _toInt(json['generalCleanliness']),
      generalNoise: _toInt(json['generalNoise']),
      // The backend may return "generalShit", "generalShittable", or
      // only "overall". Derive comfort from whichever is available.
      generalShittable: _toInt(json['generalShit'] ?? json['generalShittable'] ??
          (json['overall'] is num ? (json['overall'] as num).round() : null) ?? 0),
      sinkCleanliness: _toInt(json['sinkCleanliness'] ?? json['generalCleanliness']),
      sinkNoise: _toInt(json['sinkNoise'] ?? json['generalNoise']),
      sinkShittable: _toInt(json['sinkShit'] ?? json['sinkShittable'] ??
          (json['overall'] is num ? (json['overall'] as num).round() : null) ?? 0),
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
