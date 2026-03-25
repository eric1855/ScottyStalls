import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'models/restroom.dart';
import 'models/review.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'review_page.dart';

Color _ratingColor(double rating) {
  if (rating >= 4.0) return const Color(0xFF22C55E);
  if (rating >= 3.0) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

Widget _buildStarRowInline(String label, double avg) {
  final color = _ratingColor(avg);
  return Row(children: [
    SizedBox(
        width: 52,
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280)))),
    ...List.generate(5, (i) {
      if (i < avg.floor()) {
        return Icon(Icons.star_rounded, size: 16, color: color);
      } else if (i < avg.ceil() && avg - avg.floor() >= 0.25) {
        return Icon(Icons.star_half_rounded, size: 16, color: color);
      } else {
        return Icon(Icons.star_border_rounded,
            size: 16, color: color.withOpacity(0.3));
      }
    }),
    const SizedBox(width: 4),
    Text(avg.toStringAsFixed(1),
        style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
  ]);
}

/// A page that displays all reviews for a given [Restroom]. Users can
/// browse summaries of each review and tap on a review to see the full
/// details in a modal sheet. A floating action button allows the current
/// user to add their own review.
class ReaderReviewPage extends StatefulWidget {
  const ReaderReviewPage({super.key, required this.restroom});

  static const String routeName = '/read-reviews';

  final Restroom restroom;

  @override
  State<ReaderReviewPage> createState() => _ReaderReviewPageState();
}

class _ReaderReviewPageState extends State<ReaderReviewPage> {
  late ApiService _apiService;
  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize ApiService with the current auth token whenever dependencies change.
    final auth = context.read<AuthProvider>();
    _apiService = ApiService(baseUrl: apiBaseUrl, token: auth.user.token);
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final reviews = await _apiService.fetchReviews(widget.restroom.id);
      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      // Backend unavailable — show demo reviews
      setState(() {
        _reviews = _generateDemoReviews(widget.restroom.id);
        _hasError = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _averageGeneralRating(Review review) {
    return (review.generalCleanliness +
            review.generalNoise +
            review.generalShittable) /
        3.0;
  }

  double _averageSinkRating(Review review) {
    return (review.sinkCleanliness + review.sinkNoise + review.sinkShittable) /
        3.0;
  }

  double _overallRating(Review review) {
    return (_averageGeneralRating(review) + _averageSinkRating(review)) / 2.0;
  }

  void _showReviewDetails(Review review) {
    final overall = _overallRating(review);
    final overallColor = _ratingColor(overall);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Overall rating hero
                Center(
                  child: Column(
                    children: [
                      Text(
                        overall.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: overallColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          if (i < overall.floor()) {
                            return Icon(Icons.star_rounded,
                                size: 24, color: overallColor);
                          } else if (i < overall.ceil() &&
                              overall - overall.floor() >= 0.25) {
                            return Icon(Icons.star_half_rounded,
                                size: 24, color: overallColor);
                          } else {
                            return Icon(Icons.star_border_rounded,
                                size: 24,
                                color: overallColor.withOpacity(0.3));
                          }
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Overall Rating',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      review.username,
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRatingSection('General Bathroom Ratings', [
                  review.generalCleanliness,
                  review.generalNoise,
                  review.generalShittable,
                ]),
                const SizedBox(height: 8),
                _buildRatingSection('Sink Ratings', [
                  review.sinkCleanliness,
                  review.sinkNoise,
                  review.sinkShittable,
                ]),
                const SizedBox(height: 16),
                if (review.comment.isNotEmpty) ...[
                  Text(
                    'Comments',
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.comment,
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingSection(String title, List<int> ratings) {
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    final sectionColor = _ratingColor(avg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: sectionColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                avg.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: sectionColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: ratings.asMap().entries.map((entry) {
            final label = entry.key == 0
                ? 'Cleanliness'
                : entry.key == 1
                    ? 'Noise'
                    : 'Shittable\u2011ness';
            final value = entry.value;
            final starColor = _ratingColor(value.toDouble());
            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < value
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 16,
                        color: i < value
                            ? starColor
                            : starColor.withOpacity(0.3),
                      );
                    }),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRestroomHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.restroom.imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(widget.restroom.imageUrl),
          ),
        if (widget.restroom.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              widget.restroom.description,
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    // Format the date as e.g. Aug 19, 2025. This could be more sophisticated
    // using intl package; however for simplicity we manually compose a string.
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.restroom.name,
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Only allow authenticated users to submit reviews. Guests are
          // prompted to sign in instead of navigating to the review form.
          final auth = context.read<AuthProvider>();
          if (auth.user.isGuest) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please sign in to write a review'),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewPage(restroom: widget.restroom),
            ),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.rate_review),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : _reviews.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildRestroomHeader(),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'No reviews yet. Be the first to leave one!',
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reviews.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) return _buildRestroomHeader();
                        final review = _reviews[index - 1];
                        final avgGeneral = _averageGeneralRating(review);
                        final avgSink = _averageSinkRating(review);
                        final overall = _overallRating(review);
                        final badgeColor = _ratingColor(overall);
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showReviewDetails(review),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Color-coded rating badge
                                Container(
                                  width: 56,
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        overall.toStringAsFixed(1),
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Icon(Icons.star_rounded,
                                          size: 14, color: Colors.white.withOpacity(0.9)),
                                    ],
                                  ),
                                ),
                                // Review content
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Username + date
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                review.username,
                                                style: GoogleFonts.inter(
                                                  textStyle: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF111827),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatDate(review.createdAt),
                                              style: GoogleFonts.inter(
                                                textStyle: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // General star row
                                        _buildStarRowInline(
                                            'General', avgGeneral),
                                        const SizedBox(height: 2),
                                        // Sink star row
                                        _buildStarRowInline('Sink', avgSink),
                                        // Comment preview
                                        if (review.comment.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            review.comment,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              textStyle: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

/// Generates realistic demo reviews when the backend is unavailable.
List<Review> _generateDemoReviews(String restroomId) {
  final now = DateTime.now();
  final comments = [
    'Clean and well-maintained. Would use again.',
    'Decent but could use better soap dispensers.',
    'Great spot between classes. Never too crowded.',
    'Needs some TLC. Paper towel dispenser was empty.',
    'Best restroom in this building by far.',
  ];
  final usernames = [
    'alex_t',
    'jenny99',
    'cmu_student',
    'tartanfan',
    'reviewer42'
  ];
  return List.generate(comments.length, (i) {
    return Review(
      id: 'demo-rev-$restroomId-$i',
      restroomId: restroomId,
      userId: 'demo-user-$i',
      username: usernames[i],
      generalCleanliness: 3 + (i % 3),
      generalNoise: 2 + (i % 4),
      generalShittable: 3 + (i % 3),
      sinkCleanliness: 3 + ((i + 1) % 3),
      sinkNoise: 2 + ((i + 1) % 4),
      sinkShittable: 3 + ((i + 1) % 3),
      comment: comments[i],
      createdAt: now.subtract(Duration(days: i * 3 + 1)),
    );
  });
}
