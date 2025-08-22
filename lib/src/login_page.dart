import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'verify_code_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static const String routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _AuthMode { choose, login, register }

class _LoginPageState extends State<LoginPage> {
  _AuthMode _mode = _AuthMode.choose;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false; // debounce

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toMode(_AuthMode mode) => setState(() => _mode = mode);

  void _loginAsGuest() {
    context.read<AuthProvider>().loginAsGuest();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  String _friendlyMessage(Object error) {
    final s = error.toString();

    // Pull {"error":"..."} if present
    try {
      final m = RegExp(r'{"error"\s*:\s*"([^"]+)"}').firstMatch(s);
      if (m != null) return m.group(1)!;
    } catch (_) {}

    // Common backend patterns
    if (_mode == _AuthMode.login &&
        (s.contains('401') || s.toLowerCase().contains('invalid credentials'))) {
      return 'Username and/or password incorrect.';
    }
    if (_mode == _AuthMode.login && s.contains('404')) {
      return 'Account not found.';
    }
    if (_mode == _AuthMode.register && s.contains('409')) {
      return 'Username or email already in use.';
    }
    if (s.contains('410') || s.toLowerCase().contains('expired')) {
      return 'The code has expired. Please request a new one.';
    }
    if (s.contains('422') || s.toLowerCase().contains('required')) {
      return 'Please fill out all required fields.';
    }
    if (s.contains('502') || s.toLowerCase().contains('internal server error')) {
      return 'Server error during registration. Please try again in a moment.';
    }

    // Network-ish hints
    final lower = s.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network') ||
        lower.contains('connection refused') ||
        lower.contains('timed out')) {
      return 'Network error. Please check your connection and try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  Future<void> _submit() async {
    if (_submitting) return;
    _submitting = true;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirm  = _confirmController.text;
    final email = _emailController.text.trim();

    // Basic guardrails
    if (_mode == _AuthMode.login && (username.isEmpty || password.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username and password')),
      );
      _submitting = false;
      return;
    }
    if (_mode == _AuthMode.register &&
        (username.isEmpty || email.isEmpty || password.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username, email, and password')),
      );
      _submitting = false;
      return;
    }
    if (_mode == _AuthMode.register && password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      _submitting = false;
      return;
    }

    // Spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      late ({bool codeRequired, String username}) res;

      if (_mode == _AuthMode.login) {
        res = await auth.login(username, password);
        if (!mounted) return;
        Navigator.of(context).pop(); // close spinner
        if (res.codeRequired) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                VerifyCodePage(username: res.username, purpose: 'login'),
          ));
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        res = await auth.register(username, email, password);
        if (!mounted) return;
        Navigator.of(context).pop(); // close spinner
        if (res.codeRequired) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
                content: Text('Verification code sent. Check your email. You got 10 minutes.')));
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                VerifyCodePage(username: res.username, purpose: 'register'),
          ));
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close spinner
      final msg = _friendlyMessage(e);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      _submitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildContent(context, theme),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    switch (_mode) {
      case _AuthMode.choose:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loginAsGuest,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('LOG IN AS GUEST'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _toMode(_AuthMode.login),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('LOG IN'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _toMode(_AuthMode.register),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('REGISTER'),
            ),
          ],
        );

      case _AuthMode.login:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: _filled('Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _filled('Password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                  );
                },
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Log in'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _toMode(_AuthMode.choose),
              child: const Text('Back'),
            ),
          ],
        );

      case _AuthMode.register:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: _filled('Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: _filled('Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _filled('Password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: _filled('Confirm Password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Register'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _toMode(_AuthMode.choose),
              child: const Text('Back'),
            ),
          ],
        );
    }
  }

  InputDecoration _filled(String hint) => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      );

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Image.asset('assets/images/rainbow_poop.png', width: 80, height: 80),
        const SizedBox(height: 16),
        Text(
          'Restroom Reviewer',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            textStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ) ??
                const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
          ),
        ),
      ],
    );
  }
}
