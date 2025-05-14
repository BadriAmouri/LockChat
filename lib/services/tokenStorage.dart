// services/token_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Keys
  static const String _userid = 'user_id';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  
  // Save tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _accessTokenKey, value: accessToken); // ✅ FIXED
  }

  Future<void> saveUserId(String userid) async {
    await _storage.write(key: _userid, value: userid);
  }

  Future<void> saveUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }
  
  // Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userid);
  }
  
  // Get username
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }
  
  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  // Clear tokens on logout
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _usernameKey);
  }
}
