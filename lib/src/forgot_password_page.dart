import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _usernameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _usernameCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your username')));
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().startPasswordReset(username);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResetPasswordPage(username: username)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text("Enter your username and we'll email you a 6-digit code.",
            style: GoogleFonts.inter(fontSize: 15, color: Colors.white)),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameCtrl,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Sending\u2026' : 'Send code'),
            ),
          ),
        ]),
      ),
    );
  }
}
