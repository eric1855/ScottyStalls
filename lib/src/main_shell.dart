import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'home_page.dart';
import 'profile_page.dart';
import 'providers/restroom_provider.dart';
import 'reader_review_page.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'models/restroom.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.settingsController});
  final SettingsController settingsController;
  static const String routeName = '/main';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomePage(),
          const _ReviewsTab(),
          const ProfilePage(),
          SettingsView(controller: widget.settingsController),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1A1A1A), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rate_review_outlined),
              activeIcon: Icon(Icons.rate_review),
              label: 'Reviews',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen searchable list of restrooms.
class _ReviewsTab extends StatefulWidget {
  const _ReviewsTab();

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestroomProvider>();
    final query = _searchController.text.toLowerCase();
    final restrooms = query.isEmpty
        ? provider.restrooms
        : provider.restrooms.where((r) =>
            r.name.toLowerCase().contains(query) ||
            r.building.toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Reviews', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
                hintText: 'Search restrooms...',
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Color(0xFF666666)),
                        onPressed: () { _searchController.clear(); setState(() {}); },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: restrooms.isEmpty
                ? Center(
                    child: Text(
                      query.isEmpty ? 'Loading restrooms...' : 'No results for "$query"',
                      style: GoogleFonts.inter(color: const Color(0xFF666666)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: restrooms.length,
                    itemBuilder: (context, i) => _buildRestroomCard(context, restrooms[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestroomCard(BuildContext context, Restroom restroom) {
    final rColor = restroom.generalRating >= 4.0
        ? const Color(0xFF22C55E)
        : restroom.generalRating >= 3.0
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReaderReviewPage(restroom: restroom)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: rColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                restroom.generalRating.toStringAsFixed(1),
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: rColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restroom.name,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('${restroom.building} \u00b7 Floor ${restroom.floor}',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF888888))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF666666), size: 20),
          ],
        ),
      ),
    );
  }
}
