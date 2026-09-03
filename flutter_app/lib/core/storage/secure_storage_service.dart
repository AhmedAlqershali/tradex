import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─── SecureStorageService ─────────────────────────────────────────────────────
//
// Thin wrapper around flutter_secure_storage that centralises all key names
// and provides a clean API for token management.
//
// Only AuthService and ApiClient (for the 401-refresh interceptor) should
// import this class directly. All other code goes through UserController.
// ─────────────────────────────────────────────────────────────────────────────

class SecureStorageService {
  SecureStorageService._()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  static final SecureStorageService instance = SecureStorageService._();

  final FlutterSecureStorage _storage;

  // ── Key names ─────────────────────────────────────────────────────────────────
    static const _keyAccessToken = 'tradex_access_token';
    static const _keyRefreshToken = 'tradex_refresh_token';
    static const _keyPendingVerificationUser =
            'tradex_pending_verification_user';
    static const _keyPendingVerificationPassword =
            'tradex_pending_verification_password';

  // ── Access token ──────────────────────────────────────────────────────────────

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _keyAccessToken, value: token);

  Future<String?> readAccessToken() =>
      _storage.read(key: _keyAccessToken);

  Future<void> deleteAccessToken() =>
      _storage.delete(key: _keyAccessToken);

  // ── Refresh token ─────────────────────────────────────────────────────────────

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _keyRefreshToken, value: token);

  Future<String?> readRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  Future<void> deleteRefreshToken() =>
      _storage.delete(key: _keyRefreshToken);

    Future<void> savePendingVerification({
        required String userJson,
        required String password,
    }) async {
        await _storage.write(key: _keyPendingVerificationUser, value: userJson);
        await _storage.write(
            key: _keyPendingVerificationPassword,
            value: password,
        );
    }

    Future<String?> readPendingVerificationUser() =>
            _storage.read(key: _keyPendingVerificationUser);

    Future<String?> readPendingVerificationPassword() =>
            _storage.read(key: _keyPendingVerificationPassword);

    Future<void> clearPendingVerification() async {
        await _storage.delete(key: _keyPendingVerificationUser);
        await _storage.delete(key: _keyPendingVerificationPassword);
    }

  // ── Bulk clear ────────────────────────────────────────────────────────────────

  /// Removes all stored tokens. Call this on logout.
  Future<void> clearAll() => _storage.deleteAll();
}
