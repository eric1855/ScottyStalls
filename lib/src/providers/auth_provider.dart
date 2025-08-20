import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../device_id.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider(String baseUrl) : _service = AuthService(baseUrl: baseUrl);
  final AuthService _service;

  User _user = User.guest();
  String? _deviceId;

  User get user => _user;
  bool get isAuthenticated => !_user.isGuest;

  Future<void> _ensureDeviceId() async {
    _deviceId ??= await getOrCreateDeviceId();
  }

  Future<({bool codeRequired, String username})> register(
      String username, String email, String password) async {
    await _ensureDeviceId();
    final r = await _service.register(username: username, email: email, password: password);
    if (r.codeRequired) {
      return (codeRequired: true, username: username);
    } else if (r.user != null) {
      _user = r.user!;
      notifyListeners();
      return (codeRequired: false, username: username);
    }
    throw Exception('Unexpected register state');
  }

  Future<({bool codeRequired, String username})> login(
      String username, String password) async {
    await _ensureDeviceId();
    final r = await _service.login(
      username: username, password: password, deviceId: _deviceId!,
    );
    if (r.codeRequired) {
      return (codeRequired: true, username: username);
    } else if (r.user != null) {
      _user = r.user!;
      notifyListeners();
      return (codeRequired: false, username: username);
    }
    throw Exception('Unexpected login state');
  }

  Future<void> verifyCode({
    required String username,
    required String code,
    required String purpose,
  }) async {
    await _ensureDeviceId();
    final u = await _service.verifyCode(
      username: username, code: code, deviceId: _deviceId!, purpose: purpose,
    );
    _user = u;
    notifyListeners();
  }

  Future<void> resendCode(String username, {String purpose = 'login'}) {
    return _service.resendCode(username, purpose: purpose);
  }

  void loginAsGuest() {
    _user = User.guest();
    notifyListeners();
  }

  void logout() {
    _user = User.guest();
    notifyListeners();
  }
}
