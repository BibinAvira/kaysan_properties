import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists JWT access/refresh tokens in the platform keystore/keychain via
/// `flutter_secure_storage` — never SharedPreferences, per the API docs'
/// guidance, since these tokens grant account access.
class TokenStorage {
  static const String _accessKey = 'kaysan_access_token';
  static const String _refreshKey = 'kaysan_refresh_token';
  static const String _biometricEnabledKey = 'kaysan_biometric_enabled';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> saveAccessToken(String access) => _storage.write(key: _accessKey, value: access);

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  /// Whether the signed-in user has opted into unlocking the app with
  /// Face ID/Touch ID instead of typing their password again on relaunch.
  Future<bool> isBiometricEnabled() async {
    return await _storage.read(key: _biometricEnabledKey) == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) {
    return _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }
}
