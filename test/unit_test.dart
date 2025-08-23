// This is an example unit test.
//
// A unit test tests a single function, method, or class. To learn more about
// writing unit tests, visit
// https://flutter.dev/to/unit-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:toilet_app/src/models/review.dart';

void main() {
  group('Plus Operator', () {
    test('should add two numbers together', () {
      expect(1 + 1, 2);
    });
  });

  test('Review.fromJson parses numeric strings', () {
    final json = {
      'id': 'r1',
      'restroomId': 'rr',
      'userId': 'u1',
      'username': 'alice',
      'generalCleanliness': '5',
      'generalNoise': 4,
      'generalShittable': '3',
      'sinkCleanliness': '2',
      'sinkNoise': '1',
      'sinkShittable': 5.0,
      'comment': 'ok',
      'createdAt': '2020-01-01T00:00:00Z',
    };

    final review = Review.fromJson(json);
    expect(review.generalCleanliness, 5);
    expect(review.generalNoise, 4);
    expect(review.generalShittable, 3);
    expect(review.sinkCleanliness, 2);
    expect(review.sinkNoise, 1);
    expect(review.sinkShittable, 5);
  });
}
