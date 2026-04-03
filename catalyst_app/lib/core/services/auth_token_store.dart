import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenStore {
  static const String _accessTokenKey = 'catalyst_access_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> saveAccessToken(String token) async {
    if (token.isEmpty) return;
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> clearAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }
}
