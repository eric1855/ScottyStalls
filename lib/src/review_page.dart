import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'models/restroom.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';

Color _ratingColor(double rating) {
  if (rating >= 4.0) return const Color(0xFF22C55E);
  if (rating >= 3.0) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

Widget _buildSectionHeader(String title, IconData icon) {
  return Row(children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: const Color(0xFFC41230).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 20, color: const Color(0xFFC41230)),
    ),
    const SizedBox(width: 12),
    Text(title,
        style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700)),
  ]);
}

/// Page allowing the user to submit a review for a restroom.
///
/// Two sections are provided: one for the general bathroom experience and
/// another specifically for the sink. Each section includes ratings for
/// cleanliness, noise, and "general shittable-ness". Ratings are captured
/// using a row of stars. Once submitted, a success message is shown and the
/// user returns to the previous screen.
class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.restroom});

  static const String routeName = '/review';

  final Restroom restroom;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  // Ratings for the general restroom experience
  int _generalCleanliness = 0;
  int _generalNoise = 0;
  int _generalShit = 0;

  // Ratings for the sink area
  int _sinkCleanliness = 0;
  int _sinkNoise = 0;
  int _sinkShit = 0;

  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    final auth = context.read<AuthProvider>();
    if (auth.user.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit a review.'),
        ),
      );
      return;
    }
    // Show a loading indicator while sending the review.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final api = ApiService(baseUrl: apiBaseUrl, token: auth.user.token);
    api
        .submitReview(
          restroomId: widget.restroom.id,
          generalCleanliness: _generalCleanliness,
          generalNoise: _generalNoise,
          // Backend expects the key "generalShit" for this rating.
          generalShit: _generalShit,
          sinkCleanliness: _sinkCleanliness,
          sinkNoise: _sinkNoise,
          // Backend expects the key "sinkShit" for this rating.
          sinkShit: _sinkShit,
          comment: _commentController.text.trim(),
        )
        .then((_) {
          Navigator.of(context).pop(); // dismiss loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review submitted! Thank you.')),
          );
          Navigator.of(context).pop();
        })
        .catchError((error) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting review: $error')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.restroom.name,
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
                'General Bathroom', Icons.bathroom_rounded),
            const SizedBox(height: 12),
            _RatingRow(
              label: 'Cleanliness',
              rating: _generalCleanliness,
              onChanged: (val) => setState(() => _generalCleanliness = val),
            ),
            _RatingRow(
              label: 'Noise',
              rating: _generalNoise,
              onChanged: (val) => setState(() => _generalNoise = val),
            ),
            _RatingRow(
              label: 'General shittable\u2011ness',
              rating: _generalShit,
              onChanged: (val) => setState(() => _generalShit = val),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),
            _buildSectionHeader('Sink', Icons.wash_rounded),
            const SizedBox(height: 12),
            _RatingRow(
              label: 'Cleanliness',
              rating: _sinkCleanliness,
              onChanged: (val) => setState(() => _sinkCleanliness = val),
            ),
            _RatingRow(
              label: 'Noise',
              rating: _sinkNoise,
              onChanged: (val) => setState(() => _sinkNoise = val),
            ),
            _RatingRow(
              label: 'General shittable\u2011ness',
              rating: _sinkShit,
              onChanged: (val) => setState(() => _sinkShit = val),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),
            _buildSectionHeader(
                'Comments (optional)', Icons.comment_rounded),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _commentController,
                minLines: 4,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Write your thoughts here\u2026',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFC41230), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _submitReview,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Submit Review'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: const Color(0xFFC41230),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFFC41230).withOpacity(0.4),
                  textStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A helper widget that displays a label and a row of 5 tappable stars.
class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.label,
    required this.rating,
    required this.onChanged,
  });

  final String label;
  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final starColor = rating > 0 ? _ratingColor(rating.toDouble()) : Colors.grey.shade400;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                if (rating > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: starColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$rating/5',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: starColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              final selected = index < rating;
              return GestureDetector(
                onTap: () => onChanged(index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    selected ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 36,
                    color: selected ? starColor : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
