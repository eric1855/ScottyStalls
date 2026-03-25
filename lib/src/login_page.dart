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
  bool _submitting = false;

  static const _primary = Color(0xFFC41230);
  static const _dark = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF999999);
  static const _inputBg = Color(0xFFF5F5F5);
  static const _border = Color(0xFFE5E5E5);

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
    try {
      final m = RegExp(r'{"error"\s*:\s*"([^"]+)"}').firstMatch(s);
      if (m != null) return m.group(1)!;
    } catch (_) {}
    if (_mode == _AuthMode.login &&
        (s.contains('401') || s.toLowerCase().contains('invalid credentials'))) {
      return 'Username and/or password incorrect.';
    }
    if (_mode == _AuthMode.login && s.contains('404')) return 'Account not found.';
    if (_mode == _AuthMode.register && s.contains('409')) return 'Username or email already in use.';
    if (s.contains('410') || s.toLowerCase().contains('expired')) return 'Code expired. Request a new one.';
    if (s.contains('422') || s.toLowerCase().contains('required')) return 'Please fill out all required fields.';
    if (s.contains('502') || s.toLowerCase().contains('internal server error')) return 'Server error. Try again.';
    final lower = s.toLowerCase();
    if (lower.contains('socketexception') || lower.contains('failed host lookup') ||
        lower.contains('network') || lower.contains('connection refused') || lower.contains('timed out')) {
      return 'Network error. Check your connection.';
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

    if (_mode == _AuthMode.login && (username.isEmpty || password.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username and password')));
      _submitting = false;
      return;
    }
    if (_mode == _AuthMode.register && (username.isEmpty || email.isEmpty || password.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username, email, and password')));
      _submitting = false;
      return;
    }
    if (_mode == _AuthMode.register && password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')));
      _submitting = false;
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.white70,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _primary)),
    );

    try {
      late ({bool codeRequired, String username}) res;
      if (_mode == _AuthMode.login) {
        res = await auth.login(username, password);
        if (!mounted) return;
        Navigator.of(context).pop();
        if (res.codeRequired) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => VerifyCodePage(username: res.username, purpose: 'login')));
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()));
        }
      } else {
        res = await auth.register(username, email, password);
        if (!mounted) return;
        Navigator.of(context).pop();
        if (res.codeRequired) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Verification code sent. Check your email.')));
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => VerifyCodePage(username: res.username, purpose: 'register')));
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()));
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_friendlyMessage(e))));
    } finally {
      _submitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_mode) {
      case _AuthMode.choose:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 48),
            _buildHeader(),
            const SizedBox(height: 56),
            _primaryButton('Log In', onTap: () => _toMode(_AuthMode.login)),
            const SizedBox(height: 14),
            _primaryButton('Create Account', onTap: () => _toMode(_AuthMode.register)),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _loginAsGuest,
              child: Text('Continue as guest',
                style: GoogleFonts.inter(fontSize: 14, color: _muted,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFFCCCCCC))),
            ),
            const SizedBox(height: 48),
          ],
        );

      case _AuthMode.login:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            _buildHeader(),
            const SizedBox(height: 48),
            _field(_usernameController, 'Username'),
            const SizedBox(height: 14),
            _field(_passwordController, 'Password',
              obscure: _obscurePassword,
              toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                child: Text('Forgot password?',
                  style: GoogleFonts.inter(fontSize: 13, color: _muted)),
              ),
            ),
            const SizedBox(height: 32),
            _primaryButton('Log In', onTap: _submit),
            const SizedBox(height: 32),
            _backLink(),
            const SizedBox(height: 48),
          ],
        );

      case _AuthMode.register:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            _buildHeader(),
            const SizedBox(height: 48),
            _field(_usernameController, 'Username'),
            const SizedBox(height: 14),
            _field(_emailController, 'Email'),
            const SizedBox(height: 14),
            _field(_passwordController, 'Password',
              obscure: _obscurePassword,
              toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)),
            const SizedBox(height: 14),
            _field(_confirmController, 'Confirm password',
              obscure: _obscureConfirm,
              toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm)),
            const SizedBox(height: 32),
            _primaryButton('Create Account', onTap: _submit),
            const SizedBox(height: 32),
            _backLink(),
            const SizedBox(height: 48),
          ],
        );
    }
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.location_on_rounded, size: 40, color: _primary),
        const SizedBox(height: 24),
        Text('ScottyStalls',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 36, fontWeight: FontWeight.w300,
            color: _dark, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text('Find the best restrooms at CMU',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: _muted)),
      ],
    );
  }

  Widget _primaryButton(String text, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(text, style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint,
      {bool obscure = false, VoidCallback? toggleObscure}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.inter(fontSize: 15, color: _dark),
      cursorColor: _primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 15, color: const Color(0xFFBBBBBB)),
        filled: true,
        fillColor: _inputBg,
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                  color: _muted, size: 20),
                onPressed: toggleObscure)
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _primary, width: 1.5)),
      ),
    );
  }

  Widget _backLink() {
    return Center(
      child: GestureDetector(
        onTap: () => _toMode(_AuthMode.choose),
        child: Text('Back',
          style: GoogleFonts.inter(fontSize: 14, color: _muted)),
      ),
    );
  }
}
