import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'models/restroom.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.restroom});

  static const String routeName = '/review';

  final Restroom restroom;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _generalCleanliness = 0;
  int _generalNoise = 0;
  int _generalShit = 0;
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
        const SnackBar(content: Text('You must be logged in to submit a review.')));
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final api = ApiService(baseUrl: apiBaseUrl, token: auth.user.token);
    api.submitReview(
      restroomId: widget.restroom.id,
      generalCleanliness: _generalCleanliness,
      generalNoise: _generalNoise,
      generalShit: _generalShit,
      sinkCleanliness: _sinkCleanliness,
      sinkNoise: _sinkNoise,
      sinkShit: _sinkShit,
      comment: _commentController.text.trim(),
    ).then((_) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted! Thank you.')));
      Navigator.of(context).pop();
    }).catchError((error) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Write Review', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC41230).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC41230).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on, color: Color(0xFFC41230), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.restroom.building,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        Text('Floor ${widget.restroom.floor} \u00b7 ${widget.restroom.name}',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF888888))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rating categories
            _ratingCategory('Cleanliness', 'Is the stall and toilet area sanitary?',
              _generalCleanliness, (v) => setState(() => _generalCleanliness = v)),
            _ratingCategory('Privacy', 'Are the stall gaps minimal?',
              _generalNoise, (v) => setState(() => _generalNoise = v)),
            _ratingCategory('Noise Level', 'Can you hear your thoughts?',
              _generalShit, (v) => setState(() => _generalShit = v)),
            _ratingCategory('Paper Supply', 'Is the roll full and stocked?',
              _sinkCleanliness, (v) => setState(() => _sinkCleanliness = v)),
            _ratingCategory('Comfort', 'Overall comfort and vibes',
              _sinkNoise, (v) => setState(() => _sinkNoise = v)),
            _ratingCategory('Sink & Dryers', 'Water temp? Dryer speed?',
              _sinkShit, (v) => setState(() => _sinkShit = v)),

            const SizedBox(height: 20),
            // Comments
            Text('Additional Comments',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Tell us about the flush power or the vibes...',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              minLines: 3,
              maxLines: 6,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Write your thoughts here\u2026',
                filled: true,
                fillColor: const Color(0xFF111111),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC41230), width: 1.5)),
              ),
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Submit Review',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _ratingCategory(String label, String subtitle, int rating, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 2),
          Text(subtitle,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final selected = i < rating;
              return GestureDetector(
                onTap: () => onChanged(i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? const Color(0xFFC41230) : const Color(0xFF1A1A1A),
                      border: Border.all(
                        color: selected ? const Color(0xFFC41230) : const Color(0xFF333333),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text('${i + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : const Color(0xFF666666))),
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
