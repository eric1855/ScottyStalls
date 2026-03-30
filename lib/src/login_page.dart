import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'main_shell.dart';
import 'verify_code_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static const String routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  static const _primary = Color(0xFFC41230);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _loginAsGuest() {
    context.read<AuthProvider>().loginAsGuest();
    Navigator.of(context).pushReplacementNamed(MainShell.routeName);
  }

  String _friendlyMessage(Object error) {
    final s = error.toString();
    try {
      final m = RegExp(r'{"error"\s*:\s*"([^"]+)"}').firstMatch(s);
      if (m != null) return m.group(1)!;
    } catch (_) {}
    if (_isLogin && (s.contains('401') || s.toLowerCase().contains('invalid credentials'))) {
      return 'Username and/or password incorrect.';
    }
    if (_isLogin && s.contains('404')) return 'Account not found.';
    if (!_isLogin && s.contains('409')) return 'Username or email already in use.';
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
    final confirm = _confirmController.text;
    final email = _emailController.text.trim();

    if (_isLogin && (username.isEmpty || password.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username and password')));
      _submitting = false;
      return;
    }
    if (!_isLogin && (username.isEmpty || email.isEmpty || password.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter username, email, and password')));
      _submitting = false;
      return;
    }
    if (!_isLogin && password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')));
      _submitting = false;
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _primary)),
    );

    try {
      late ({bool codeRequired, String username}) res;
      if (_isLogin) {
        res = await auth.login(username, password);
        if (!mounted) return;
        Navigator.of(context).pop();
        if (res.codeRequired) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => VerifyCodePage(username: res.username, purpose: 'login')));
        } else {
          Navigator.of(context).pushReplacementNamed(MainShell.routeName);
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
          Navigator.of(context).pushReplacementNamed(MainShell.routeName);
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 48),
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE8163B), Color(0xFF9E0E27)],
                      ),
                      boxShadow: [
                        BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
                      ],
                    ),
                    child: const Icon(Icons.location_on_rounded, size: 42, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text('ScottyStalls',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text('Find the best restrooms at CMU',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFF888888))),
                  const SizedBox(height: 32),
                  // Tab toggle
                  _buildTabToggle(),
                  const SizedBox(height: 28),
                  // Form fields
                  if (_isLogin) ..._buildLoginFields()
                  else ..._buildRegisterFields(),
                  const SizedBox(height: 28),
                  // Submit button
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_isLogin ? 'Sign In' : 'Create Account',
                            style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // OR divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFF333333))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR CONTINUE WITH',
                          style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: const Color(0xFF666666), letterSpacing: 0.5)),
                      ),
                      const Expanded(child: Divider(color: Color(0xFF333333))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Guest access
                  GestureDetector(
                    onTap: _loginAsGuest,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF444444), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text('Guest Access',
                        style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabButton('Login', _isLogin, () => setState(() => _isLogin = true)),
          _tabButton('Register', !_isLogin, () => setState(() => _isLogin = false)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF333333) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }

  List<Widget> _buildLoginFields() {
    return [
      _buildField(_usernameController, 'USERNAME', 'Enter your username',
        icon: Icons.person_outline),
      const SizedBox(height: 16),
      _buildField(_passwordController, 'PASSWORD', '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
        icon: Icons.lock_outline,
        obscure: _obscurePassword,
        toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
          child: Text('Forgot password?',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF888888))),
        ),
      ),
    ];
  }

  List<Widget> _buildRegisterFields() {
    return [
      _buildField(_usernameController, 'USERNAME', 'Choose a username',
        icon: Icons.person_outline),
      const SizedBox(height: 16),
      _buildField(_emailController, 'ANDREW EMAIL', 'scotty@andrew.cmu.edu',
        icon: Icons.mail_outline),
      const SizedBox(height: 16),
      _buildField(_passwordController, 'PASSWORD', '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
        icon: Icons.lock_outline,
        obscure: _obscurePassword,
        toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword)),
      const SizedBox(height: 16),
      _buildField(_confirmController, 'CONFIRM PASSWORD', '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
        icon: Icons.lock_outline,
        obscure: _obscureConfirm,
        toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm)),
    ];
  }

  Widget _buildField(TextEditingController controller, String label, String hint,
      {IconData? icon, bool obscure = false, VoidCallback? toggleObscure}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: const Color(0xFF888888), letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
          cursorColor: _primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF555555)),
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF666666), size: 20)
                : null,
            suffixIcon: toggleObscure != null
                ? IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF666666), size: 20),
                    onPressed: toggleObscure)
                : null,
            filled: true,
            fillColor: const Color(0xFF111111),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
