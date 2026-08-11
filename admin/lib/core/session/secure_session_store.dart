import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Only the refresh token is retained and Android Keystore backs the storage.
/// Access tokens remain in memory and are cleared on logout/session failure.
class SecureSessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _refreshTokenKey = 'lafavola_admin_refresh_token';
  final FlutterSecureStorage _storage;

  Future<void> saveRefreshToken(String refreshToken) =>
      _storage.write(key: _refreshTokenKey, value: refreshToken);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> clear() => _storage.delete(key: _refreshTokenKey);
}
