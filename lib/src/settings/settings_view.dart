import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../login_page.dart';
import 'settings_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // APPEARANCE
            _sectionLabel('APPEARANCE'),
            const SizedBox(height: 12),
            _buildThemeToggle(context),
            const SizedBox(height: 28),

            // PREFERENCES
            _sectionLabel('PREFERENCES'),
            const SizedBox(height: 12),
            _prefItem(Icons.notifications_outlined, 'Push Notifications', 'Enabled'),
            _prefItem(Icons.straighten, 'Unit System', 'Metric (m)'),
            _prefItem(Icons.location_city, 'Default Campus', 'CMU Main'),
            const SizedBox(height: 28),

            // ABOUT
            _sectionLabel('ABOUT SCOTTYSTALLS'),
            const SizedBox(height: 12),
            _menuItem(Icons.privacy_tip_outlined, 'Privacy Policy'),
            _menuItem(Icons.description_outlined, 'Terms of Service'),
            _prefItem(Icons.info_outline, 'App Version', 'v2.1.0'),
            const SizedBox(height: 28),

            // Log Out
            GestureDetector(
              onTap: () {
                context.read<AuthProvider>().logout();
                Navigator.of(context).pushReplacementNamed(LoginPage.routeName);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Color(0xFFC41230), size: 20),
                    const SizedBox(width: 12),
                    Text('Log Out',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFFC41230))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text('MADE WITH \u2764\ufe0f FOR CMU STUDENTS',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF444444), letterSpacing: 0.5)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: const Color(0xFFC41230)),
        const SizedBox(width: 8),
        Text(text,
          style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: const Color(0xFF888888), letterSpacing: 1)),
      ],
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final current = controller.themeMode;
    return Row(
      children: [
        _themeButton(context, Icons.phone_android, 'SYSTEM', ThemeMode.system, current),
        const SizedBox(width: 8),
        _themeButton(context, Icons.light_mode_outlined, 'LIGHT', ThemeMode.light, current),
        const SizedBox(width: 8),
        _themeButton(context, Icons.dark_mode, 'DARK', ThemeMode.dark, current),
      ],
    );
  }

  Widget _themeButton(BuildContext context, IconData icon, String label, ThemeMode mode, ThemeMode current) {
    final active = mode == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.updateThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1A1A1A) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? const Color(0xFFC41230) : const Color(0xFF2A2A2A),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: active ? const Color(0xFFC41230) : const Color(0xFF666666)),
              const SizedBox(height: 6),
              Text(label,
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: active ? Colors.white : const Color(0xFF666666),
                  letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _prefItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
          Text(value,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666))),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
