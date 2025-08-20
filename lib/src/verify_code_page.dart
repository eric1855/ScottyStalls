import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'home_page.dart';

class VerifyCodePage extends StatefulWidget {
  const VerifyCodePage({super.key, required this.username, required this.purpose});
  final String username;
  final String purpose; // 'register' or 'login'

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() { _codeCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(()=> _loading = true);
    try {
      await context.read<AuthProvider>().verifyCode(
        username: widget.username,
        code: _codeCtrl.text.trim(),
        purpose: widget.purpose,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(()=> _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await context.read<AuthProvider>().resendCode(
        widget.username, purpose: widget.purpose,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code resent. Check your email.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(
            'Enter the 6-digit code we sent to your email.',
            style: GoogleFonts.inter(fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Verification code',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_loading ? 'Verifying…' : 'Verify'),
            ),
          ),
          TextButton(
            onPressed: _resending ? null : _resend,
            child: _resending ? const Text('Resending…') : const Text('Resend code'),
          )
        ]),
      ),
    );
  }
}
