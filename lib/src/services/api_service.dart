import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restroom.dart';
import '../models/review.dart';

/// A lightweight wrapper around the backend REST API. All methods return
/// domain objects or throw an [Exception] on failure. You must supply the
/// `baseUrl` of your deployed API Gateway stage and optionally an
/// authentication token if the endpoint requires it.
class ApiService {
  final String baseUrl;
  final String? token;

  const ApiService({required this.baseUrl, this.token});

  /// Generic GET helper that appends the path to the base URL and
  /// automatically attaches the Authorization header when a token is
  /// available. Throws an [Exception] if the response status code is not
  /// successful.
  Future<http.Response> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'GET $path failed: ${response.statusCode} ${response.body}');
    }
    return response;
  }

  /// Generic POST helper that appends the path to the base URL and
  /// automatically attaches the Authorization header when a token is
  /// available. The [body] will be encoded as JSON. Throws an [Exception]
  /// if the request fails.
  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'POST $path failed: ${response.statusCode} ${response.body}');
    }
    return response;
  }

  /// Retrieves the list of available restrooms from the backend. The backend
  /// returns a JSON array of restroom objects. Each object is converted
  /// into a [Restroom] instance using the constructor defined in
  /// `models/restroom.dart`.
  Future<List<Restroom>> fetchRestrooms() async {
    final response = await _get('/restrooms');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => Restroom.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches all reviews for a given restroom. The backend returns an array
  /// of review objects, which are converted into [Review] instances. If no
  /// reviews are found an empty list is returned.
  Future<List<Review>> fetchReviews(String restroomId) async {
    final response = await _get('/restrooms/$restroomId/reviews');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Submits a new review for the specified restroom. Ratings must be
  /// integers from 1–5. The backend returns the created review object on
  /// success which we ignore here. If the user is not authenticated or
  /// validation fails an [Exception] is thrown.
  Future<void> submitReview({
    required String restroomId,
    required int generalCleanliness,
    required int generalNoise,
    required int generalShittable,
    required int sinkCleanliness,
    required int sinkNoise,
    required int sinkShittable,
    String? comment,
  }) async {
    await _post('/restrooms/$restroomId/reviews', {
      'generalCleanliness': generalCleanliness,
      'generalNoise': generalNoise,
      'generalShittable': generalShittable,
      'sinkCleanliness': sinkCleanliness,
      'sinkNoise': sinkNoise,
      'sinkShittable': sinkShittable,
      'comment': comment ?? '',
    });
  }
}
