import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config.dart';

class AuthResult {
  final User? user;
  final bool codeRequired;
  const AuthResult({this.user, this.codeRequired = false});
}

class AuthService {
  final String baseUrl;
  const AuthService({required this.baseUrl});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'x-api-key': apiKey,
      };

  Uri _u(String p) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final path = p.startsWith('/') ? p : '/$p';
    return Uri.parse('$base$path');
  }

  /// Unwraps API Gateway payloads:
  /// - plain JSON {..}
  /// - proxy-wrapped { statusCode, body: "..." }
  /// - double-encoded strings
  dynamic _unwrap(http.Response resp) {
    dynamic data;
    try {
      data = jsonDecode(resp.body);
    } catch (_) {
      // body wasn't JSON; return raw string
      return resp.body;
    }
    if (data is Map && data.containsKey('body')) {
      final b = data['body'];
      if (b is String) {
        try {
          final inner = jsonDecode(b);
          return inner;
        } catch (_) {
          return b; // leave as string
        }
      }
      return b; // already an object
    }
    return data;
  }

  User _toUser(Map u, String token) => User(
        id: (u['userId'] ?? u['id'] ?? '').toString(),
        username: (u['username'] ?? '').toString(),
        email: u['email']?.toString() ?? '',
        isGuest: u['isGuest'] == true,
        token: token,
        poopCount: int.tryParse(u['poopCount']?.toString() ?? '') ?? 0,
        poopStreak: int.tryParse(u['poopStreak']?.toString() ?? '') ?? 0,
        poopMapDistance:
            double.tryParse(u['poopMapDistance']?.toString() ?? '') ?? 0.0,
      );

  // ---------- Register ----------
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final resp = await http.post(
      _u('/register'),
      headers: _headers,
      body: jsonEncode(
          {'username': username, 'email': email, 'password': password}),
    );

    final decoded = _unwrap(resp);

    // 202 => explicitly verification required
    if (resp.statusCode == 202) {
      return const AuthResult(codeRequired: true);
    }

    // Any 2xx
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      // Immediate success case: { user, token }
      if (decoded is Map &&
          decoded['user'] is Map &&
          decoded['token'] is String) {
        return AuthResult(
            user: _toUser(decoded['user'] as Map, decoded['token'] as String));
      }

      // Explicit status flag
      if (decoded is Map) {
        final status =
            (decoded['status'] ?? decoded['Status'] ?? '').toString();
        if (status.toUpperCase() == 'VERIFICATION_REQUIRED') {
          return const AuthResult(codeRequired: true);
        }
        final body = decoded['body'];
        if (body is Map) {
          final s2 = (body['status'] ?? body['Status'] ?? '').toString();
          if (s2.toUpperCase() == 'VERIFICATION_REQUIRED') {
            return const AuthResult(codeRequired: true);
          }
          if (body['user'] is Map && body['token'] is String) {
            return AuthResult(
                user: _toUser(body['user'] as Map, body['token'] as String));
          }
        }
      }

      // Bare string with a status hint
      if (decoded is String &&
          decoded.toUpperCase().contains('VERIFICATION_REQUIRED')) {
        return const AuthResult(codeRequired: true);
      }

      // Fallback: treat unrecognized 2xx as verification required
      return const AuthResult(codeRequired: true);
    }

    throw Exception('Registration failed: ${resp.statusCode} ${resp.body}');
  }

  // ---------- Login ----------
  Future<AuthResult> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    final resp = await http.post(
      _u('/login'),
      headers: _headers,
      body: jsonEncode(
          {'username': username, 'password': password, 'deviceId': deviceId}),
    );
    final decoded = _unwrap(resp);

    // 202 => code required (email code sent)
    if (resp.statusCode == 202) {
      return const AuthResult(codeRequired: true);
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      // Immediate success case: { user, token }
      if (decoded is Map &&
          decoded['user'] is Map &&
          decoded['token'] is String) {
        return AuthResult(
            user: _toUser(decoded['user'] as Map, decoded['token'] as String));
      }

      // Some stacks return 2xx + status text (be liberal)
      if (decoded is Map) {
        final status = (decoded['status'] ?? decoded['Status'] ?? '')
            .toString()
            .toUpperCase();
        if (status.contains('CODE') || status.contains('VERIFICATION')) {
          return const AuthResult(codeRequired: true);
        }
        final body = decoded['body'];
        if (body is Map) {
          final s2 =
              (body['status'] ?? body['Status'] ?? '').toString().toUpperCase();
          if (s2.contains('CODE') || s2.contains('VERIFICATION')) {
            return const AuthResult(codeRequired: true);
          }
          if (body['user'] is Map && body['token'] is String) {
            return AuthResult(
                user: _toUser(body['user'] as Map, body['token'] as String));
          }
        }
      }

      if (decoded is String) {
        final up = decoded.toUpperCase();
        if (up.contains('CODE') || up.contains('VERIFICATION')) {
          return const AuthResult(codeRequired: true);
        }
      }

      // As a last resort: if it’s 2xx but no token, assume verification needed
      return const AuthResult(codeRequired: true);
    }

    throw Exception('Login failed: ${resp.statusCode} ${resp.body}');
  }

  // ---------- Verify (register/login) ----------
  Future<User> verifyCode({
    required String username,
    required String code,
    required String deviceId,
    String purpose = 'login',
  }) async {
    final resp = await http.post(
      _u('/verify'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'code': code,
        'deviceId': deviceId,
        'purpose': purpose
      }),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Verify failed: ${resp.statusCode} ${resp.body}');
    }
    final decoded = _unwrap(resp);
    if (decoded is Map &&
        decoded['user'] is Map &&
        decoded['token'] is String) {
      return _toUser(decoded['user'] as Map, decoded['token'] as String);
    }
    throw Exception('Unexpected verify response');
  }

  // ---------- Resend code ----------
  Future<void> resendCode(String username, {String purpose = 'login'}) async {
    final resp = await http.post(
      _u('/resend'),
      headers: _headers,
      body: jsonEncode({'username': username, 'purpose': purpose}),
    );

    // Accept any 2xx
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final decoded = _unwrap(resp);

      // Bubble up server-declared errors if present
      if (decoded is Map && decoded['error'] is String) {
        throw Exception('Resend failed: ${decoded['error']}');
      }

      // Our Lambda returns delivery: "SENT" | "FAILED_TO_SEND"
      if (decoded is Map && decoded['delivery'] == 'FAILED_TO_SEND') {
        throw Exception(
            "We couldn't email the code right now. Please try again.");
      }

      return; // success
    }

    // Helpful hint for common API Gateway mis-route
    if (resp.statusCode == 403 &&
        resp.body.contains('Missing Authentication Token')) {
      throw Exception(
          'Resend failed: API path not found. Check baseUrl (must include the stage) and the /resend route.');
    }

    throw Exception('Resend failed: ${resp.statusCode} ${resp.body}');
  }

  // ---------- Forgot / Reset password ----------
  Future<void> startPasswordReset(String username) async {
    final resp = await http.post(
      _u('/forgot'),
      headers: _headers,
      body: jsonEncode({'username': username}),
    );
    if (resp.statusCode != 202) {
      throw Exception(
          'Forgot password failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<User> completePasswordReset({
    required String username,
    required String code,
    required String newPassword,
    String? deviceId,
  }) async {
    final resp = await http.post(
      _u('/reset'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'code': code,
        'newPassword': newPassword,
        if (deviceId != null) 'deviceId': deviceId,
      }),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Reset failed: ${resp.statusCode} ${resp.body}');
    }
    final decoded = _unwrap(resp);
    if (decoded is Map &&
        decoded['user'] is Map &&
        decoded['token'] is String) {
      return _toUser(decoded['user'] as Map, decoded['token'] as String);
    }
    throw Exception('Unexpected reset response');
  }
}
