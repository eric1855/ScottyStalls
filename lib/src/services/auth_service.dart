import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthResult {
  final User? user;
  final bool codeRequired;
  const AuthResult({this.user, this.codeRequired = false});
}

class AuthService {
  final String baseUrl;
  const AuthService({required this.baseUrl});

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Uri _u(String path) {
    final b = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$b$p');
  }

  dynamic _unwrap(http.Response resp) {
    dynamic data = jsonDecode(resp.body);
    if (data is Map &&
        data.containsKey('body') &&
        (data.containsKey('statusCode') || data.containsKey('StatusCode'))) {
      final b = data['body'];
      data = b is String ? jsonDecode(b) : b;
    }
    return data;
  }

  User _toUser(Map u, String token) => User(
        id: (u['userId'] ?? u['id'] ?? '').toString(),
        username: (u['username'] ?? '').toString(),
        email: u['email']?.toString() ?? '',
        isGuest: u['isGuest'] == true,
        token: token,
      );

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final resp = await http.post(
      _u('/register'), headers: _headers,
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    final decoded = _unwrap(resp);

    if (resp.statusCode == 202) {
      return const AuthResult(codeRequired: true);
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300 && decoded is Map) {
      if (decoded['user'] is Map && decoded['token'] is String) {
        return AuthResult(user: _toUser(decoded['user'] as Map, decoded['token'] as String));
      }
    }
    throw Exception('Registration failed: ${resp.statusCode} ${resp.body}');
  }

  Future<AuthResult> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    final resp = await http.post(
      _u('/login'), headers: _headers,
      body: jsonEncode({'username': username, 'password': password, 'deviceId': deviceId}),
    );
    final decoded = _unwrap(resp);

    if (resp.statusCode == 202) {
      return const AuthResult(codeRequired: true);
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300 && decoded is Map) {
      if (decoded['user'] is Map && decoded['token'] is String) {
        return AuthResult(user: _toUser(decoded['user'] as Map, decoded['token'] as String));
      }
    }
    throw Exception('Login failed: ${resp.statusCode} ${resp.body}');
  }

  Future<User> verifyCode({
    required String username,
    required String code,
    required String deviceId,
    String purpose = 'login',
  }) async {
    final resp = await http.post(
      _u('/verify'), headers: _headers,
      body: jsonEncode({'username': username, 'code': code, 'deviceId': deviceId, 'purpose': purpose}),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Verify failed: ${resp.statusCode} ${resp.body}');
    }
    final decoded = _unwrap(resp);
    if (decoded is Map && decoded['user'] is Map && decoded['token'] is String) {
      return _toUser(decoded['user'] as Map, decoded['token'] as String);
    }
    throw Exception('Unexpected verify response');
  }

  Future<void> resendCode(String username, {String purpose = 'login'}) async {
    final resp = await http.post(
      _u('/resend'), headers: _headers,
      body: jsonEncode({'username': username, 'purpose': purpose}),
    );
    if (resp.statusCode != 202) {
      throw Exception('Resend failed: ${resp.statusCode} ${resp.body}');
    }
  }
  
  Future<void> startPasswordReset(String username) async {
    final resp = await http.post(
      _u('/forgot'), headers: _headers,
      body: jsonEncode({'username': username}),
    );
    if (resp.statusCode != 202) {
      throw Exception('Forgot password failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<User> completePasswordReset({
    required String username,
    required String code,
    required String newPassword,
    String? deviceId,
  }) async {
    final resp = await http.post(
      _u('/reset'), headers: _headers,
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
    if (decoded is Map && decoded['user'] is Map && decoded['token'] is String) {
      return _toUser(decoded['user'] as Map, decoded['token'] as String);
    }
    throw Exception('Unexpected reset response');
  }
}
