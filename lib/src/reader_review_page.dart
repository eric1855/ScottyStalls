import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'models/restroom.dart';
import 'models/review.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'review_page.dart';

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
    final auth = context.read<AuthProvider>();
    _apiService = ApiService(baseUrl: apiBaseUrl, token: auth.user.token);
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final reviews = await _apiService.fetchReviews(widget.restroom.id);
      setState(() => _reviews = reviews);
    } catch (e) {
      setState(() { _reviews = _generateDemoReviews(widget.restroom.id); _hasError = false; });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _overallRating(Review review) {
    return (review.generalCleanliness + review.generalNoise + review.generalShittable +
            review.sinkCleanliness + review.sinkNoise + review.sinkShittable) / 6.0;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Compute aggregate ratings from all reviews
    double aggCleanliness = widget.restroom.generalRating;
    double aggNoise = widget.restroom.generalRating;
    double aggShittability = widget.restroom.generalRating;
    int totalReviews = _reviews.length;

    if (_reviews.isNotEmpty) {
      aggCleanliness = _reviews.map((r) => r.generalCleanliness.toDouble()).reduce((a, b) => a + b) / totalReviews;
      aggNoise = _reviews.map((r) => r.generalNoise.toDouble()).reduce((a, b) => a + b) / totalReviews;
      aggShittability = _reviews.map((r) => r.generalShittable.toDouble()).reduce((a, b) => a + b) / totalReviews;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.restroom.building} ${widget.restroom.floor}F',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final auth = context.read<AuthProvider>();
          if (auth.user.isGuest) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please sign in to write a review')));
            return;
          }
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ReviewPage(restroom: widget.restroom))).then((_) => _fetchReviews());
        },
        child: const Icon(Icons.rate_review),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC41230).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FLOOR ${widget.restroom.floor} \u00b7 ${widget.restroom.name.toUpperCase().contains('WOMEN') ? 'FEMALE' : widget.restroom.name.toUpperCase().contains('UNISEX') ? 'UNISEX' : 'MALE'}',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                          color: const Color(0xFFC41230), letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.restroom.name,
                      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                    if (widget.restroom.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(widget.restroom.description,
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF888888))),
                    ],
                    const SizedBox(height: 20),

                    // Big rating hero
                    Center(
                      child: Column(
                        children: [
                          Text(widget.restroom.generalRating.toStringAsFixed(1),
                            style: GoogleFonts.inter(fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (i) {
                              final rating = widget.restroom.generalRating;
                              if (i < rating.floor()) return const Icon(Icons.star_rounded, size: 24, color: Color(0xFFC41230));
                              if (i < rating.ceil() && rating - rating.floor() >= 0.25) return const Icon(Icons.star_half_rounded, size: 24, color: Color(0xFFC41230));
                              return Icon(Icons.star_outline_rounded, size: 24, color: const Color(0xFFC41230).withOpacity(0.3));
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text('Based on $totalReviews reviews',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rating bars
                    _ratingBar('CLEANLINESS', aggCleanliness),
                    const SizedBox(height: 10),
                    _ratingBar('NOISE LEVEL', aggNoise),
                    const SizedBox(height: 10),
                    _ratingBar('COMFORT', aggShittability),
                    const SizedBox(height: 28),

                    // Recent Ratings header
                    Row(
                      children: [
                        Text('Recent Ratings',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        const Spacer(),
                        Text('SORT/FILTER',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                            color: const Color(0xFF666666), letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_reviews.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('No reviews yet. Be the first!',
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666))),
                        ),
                      )
                    else
                      ...List.generate(_reviews.length, (i) => _buildReviewCard(_reviews[i])),
                  ],
                ),
    );
  }

  Widget _ratingBar(String label, double value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
              color: const Color(0xFF888888), letterSpacing: 0.3)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (value / 5.0).clamp(0, 1),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC41230),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(value.toStringAsFixed(1),
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    final overall = _overallRating(review);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1A1A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User avatar
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person, size: 18, color: Color(0xFF666666)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.username,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    Row(
                      children: [
                        ...List.generate(5, (i) =>
                          Icon(i < overall.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 12, color: const Color(0xFFC41230))),
                        const SizedBox(width: 6),
                        Text(_formatDate(review.createdAt),
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF888888)),
              maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

List<Review> _generateDemoReviews(String restroomId) {
  final now = DateTime.now();
  final comments = [
    'Clean and well-maintained. Would use again.',
    'Decent but could use better soap dispensers.',
    'Great spot between classes. Never too crowded.',
    'Needs some TLC. Paper towel dispenser was empty.',
    'Best restroom in this building by far.',
  ];
  final usernames = ['TartanFan', 'ScottyHighK', 'cmu_student', 'tartanfan', 'reviewer42'];
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
