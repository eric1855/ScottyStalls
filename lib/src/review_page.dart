import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'models/restroom.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';

/// Page allowing the user to submit a review for a restroom.
///
/// Two sections are provided: one for the general bathroom experience and
/// another specifically for the sink. Each section includes ratings for
/// cleanliness, noise, and "general shittable‑ness". Ratings are captured
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
    const String apiBaseUrl = 'https://your-api-id.execute-api.your-region.amazonaws.com/prod';
    final api = ApiService(baseUrl: apiBaseUrl, token: auth.user.token);
    api
        .submitReview(
      restroomId: widget.restroom.id,
      generalCleanliness: _generalCleanliness,
      generalNoise: _generalNoise,
      generalShittable: _generalShit,
      sinkCleanliness: _sinkCleanliness,
      sinkNoise: _sinkNoise,
      sinkShittable: _sinkShit,
      comment: _commentController.text.trim(),
    )
        .then((_) {
      Navigator.of(context).pop(); // dismiss loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted! Thank you.')),
      );
      Navigator.of(context).pop();
    }).catchError((error) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $error')),
      );
    });
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
            Text(
              'General Bathroom',
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
              label: 'General shittable‑ness',
              rating: _generalShit,
              onChanged: (val) => setState(() => _generalShit = val),
            ),
            const SizedBox(height: 24),
            Text(
              'Sink',
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
              label: 'General shittable‑ness',
              rating: _sinkShit,
              onChanged: (val) => setState(() => _sinkShit = val),
            ),
            const SizedBox(height: 24),
            Text(
              'Comments (optional)',
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write your thoughts here…',
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
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit Review'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              final selected = index < rating;
              return IconButton(
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  selected ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () => onChanged(index + 1),
              );
            }),
          ),
        ],
      ),
    );
  }
}