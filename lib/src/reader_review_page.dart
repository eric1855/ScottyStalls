import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'models/restroom.dart';
import 'models/review.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'review_page.dart';

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
    // Retrieve the base URL from the AuthProvider's constructor via reflection. Since it's
    // not exposed, we assume the same base URL used in AuthProvider. In practice you
    // should share the API base URL through a central config.
    const String apiBaseUrl =
        'https://atq65hnu62.execute-api.us-east-1.amazonaws.com/first';
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
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
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

  void _showReviewDetails(Review review) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 4),
        Row(
          children: ratings.asMap().entries.map((entry) {
            final label = entry.key == 0
                ? 'Cleanliness'
                : entry.key == 1
                    ? 'Noise'
                    : 'Shittable‑ness';
            final value = entry.value;
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
                        i < value ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
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
                        return InkWell(
                          onTap: () => _showReviewDetails(review),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        review.username,
                                        style: GoogleFonts.inter(
                                          textStyle: const TextStyle(
                                            fontSize: 16,
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
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // general rating stars
                                    Row(
                                      children: List.generate(5, (i) {
                                        return Icon(
                                          i < avgGeneral.round()
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 16,
                                          color: Colors.amber,
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'General: ${avgGeneral.toStringAsFixed(1)}',
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Row(
                                      children: List.generate(5, (i) {
                                        return Icon(
                                          i < avgSink.round()
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 16,
                                          color: Colors.amber,
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Sink: ${avgSink.toStringAsFixed(1)}',
                                      style: GoogleFonts.inter(
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (review.comment.isNotEmpty)
                                  Text(
                                    review.comment,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF374151),
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
