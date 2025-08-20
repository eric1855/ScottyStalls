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
    return Review(
      id: json['id'] as String,
      restroomId: json['restroomId'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      generalCleanliness: json['generalCleanliness'] as int,
      generalNoise: json['generalNoise'] as int,
      generalShittable: json['generalShittable'] as int,
      sinkCleanliness: json['sinkCleanliness'] as int,
      sinkNoise: json['sinkNoise'] as int,
      sinkShittable: json['sinkShittable'] as int,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}