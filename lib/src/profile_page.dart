import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const String routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // Avatar
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A1A),
                  border: Border.all(color: const Color(0xFF2A2A2A), width: 2),
                ),
                child: const Icon(Icons.person_rounded, size: 56, color: Color(0xFFC41230)),
              ),
            ),
            const SizedBox(height: 16),
            if (user.isGuest) ...[
              Text('Guest Mode',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Create an account to leave reviews and track your stats.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF888888))),
            ] else ...[
              Text(user.username,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(user.email,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF888888))),
            ],

            if (!user.isGuest) ...[
              const SizedBox(height: 28),
              // YOUR IMPACT card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC41230).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR IMPACT',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: const Color(0xFFC41230), letterSpacing: 1)),
                    const SizedBox(height: 16),
                    // Main stat
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC41230).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.rate_review_rounded, color: Color(0xFFC41230), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.poopCount.toString(),
                              style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                            Text('STALLS REVIEWED',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                                color: const Color(0xFF888888), letterSpacing: 0.5)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF2A2A2A)),
                    const SizedBox(height: 16),
                    // Secondary stats
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${user.poopStreak}',
                                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                                  const SizedBox(width: 6),
                                  if (user.poopStreak > 3)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('HOT',
                                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFF59E0B))),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('DAY STREAK',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                                  color: const Color(0xFF666666), letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: const Color(0xFF2A2A2A)),
                        Expanded(
                          child: Column(
                            children: [
                              Text('${user.poopMapDistance.toStringAsFixed(1)} mi',
                                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text('STALL DISTANCE',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                                  color: const Color(0xFF666666), letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),
            // ACCOUNT section
            if (!user.isGuest) ...[
              Text('ACCOUNT',
                style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: const Color(0xFF666666), letterSpacing: 1)),
              const SizedBox(height: 12),
              _menuItem(Icons.history, 'Contribution History'),
              _menuItem(Icons.emoji_events_outlined, 'Achievements & Badges'),
              _menuItem(Icons.tune, 'App Preferences'),
              const SizedBox(height: 20),
            ],

            // Logout button
            GestureDetector(
              onTap: () {
                context.read<AuthProvider>().logout();
                Navigator.of(context).pushReplacementNamed(LoginPage.routeName);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC41230), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, color: Color(0xFFC41230), size: 18),
                    const SizedBox(width: 8),
                    Text(user.isGuest ? 'Return to Login' : 'Log Out of ScottyStalls',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFC41230))),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Color(0xFFC41230), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('SCOTTYSTALLS V2.4.0',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF444444))),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF888888), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF444444), size: 20),
        ],
      ),
    );
  }
}
