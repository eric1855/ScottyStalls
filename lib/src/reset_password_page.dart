// lib/reset_password_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'home_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.username});
  final String username;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _codeCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  bool _obscure = true;

  @override
  void dispose() { _codeCtrl.dispose(); _newPwCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(()=> _loading = true);
    try {
      await context.read<AuthProvider>().completePasswordReset(
        username: widget.username,
        code: _codeCtrl.text.trim(),
        newPassword: _newPwCtrl.text,
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
    setState(()=> _resending = true);
    try {
      await context.read<AuthProvider>().resendCode(widget.username, purpose: 'reset');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code resent. Check your email.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(()=> _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: '6-digit code', counterText: ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPwCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'New password',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(()=> _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Resetting…' : 'Reset password'),
            ),
          ),
          TextButton(
            onPressed: _resending ? null : _resend,
            child: _resending ? const Text('Resending…') : const Text('Resend code'),
          ),
        ]),
      ),
    );
  }
}
