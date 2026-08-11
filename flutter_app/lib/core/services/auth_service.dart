import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/shared/users/user_model.dart';

// ─── Value objects ────────────────────────────────────────────────────────────

class AuthTokens {
  const AuthTokens({required this.accessToken, this.refreshToken});
  final String accessToken;

  /// The backend (Laravel Sanctum) issues a single long-lived token per
  /// login/register call — there is no refresh-token concept or /auth/refresh
  /// endpoint. Kept nullable so ApiClient's 401 handler degrades safely
  /// (falls straight through to clearing the session) instead of crashing.
  final String? refreshToken;
}

class AuthResult {
  const AuthResult({required this.user, required this.tokens});
  final AppUser user;
  final AuthTokens tokens;
}

// ─── AuthService ──────────────────────────────────────────────────────────────
//
// All authentication API calls. Every method is a thin HTTP wrapper — no state,
// no notifiers. UserController orchestrates state; AuthService only does I/O.
// ─────────────────────────────────────────────────────────────────────────────

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Login ─────────────────────────────────────────────────────────────────────
  /// POST /auth/login
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return _parseAuthResult(response.data!);
  }

  /// POST /auth/google
  ///
  /// [credential] is the Google OpenID Connect ID token. Laravel verifies
  /// this token and returns the same Sanctum auth envelope as password login.
  Future<AuthResult> loginWithGoogle({
    required String credential,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.googleLogin,
      data: {
        'credential': credential,
        'device_name': 'flutter_app',
      },
    );
    return _parseAuthResult(response.data!);
  }

  // ── Register ──────────────────────────────────────────────────────────────────
  // Backend has two separate endpoints — client registration creates a user
  // only; merchant registration creates a user AND a store atomically, so it
  // requires storeName. Both require password_confirmation.

  /// POST /auth/register/client
  Future<AuthResult> registerClient({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.registerClient,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
      },
    );
    return _parseAuthResult(response.data!);
  }

  /// POST /auth/register/merchant
  /// [storeName] is required by the backend at registration time (the store
  /// row is created in the same transaction as the user).
  Future<AuthResult> registerMerchant({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String storeName,
    String? storeDescription,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.registerMerchant,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        'store_name': storeName,
        if (storeDescription != null && storeDescription.isNotEmpty)
          'store_description': storeDescription,
      },
    );
    return _parseAuthResult(response.data!);
  }

  // ── Get current user ──────────────────────────────────────────────────────────
  /// GET /profile
  Future<AppUser> getCurrentUser() async {
    final response =
        await ApiClient.instance.get<Map<String, dynamic>>(ApiConstants.me);
    final raw = response.data!;
    // Handle both wrapped { data: {...} } and flat responses.
    final userJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return AppUser.fromServerJson(userJson);
  }

  // ── Resend verification email ─────────────────────────────────────────────────
  /// POST /auth/email/resend
  /// The backend verifies email ownership via a signed link sent by email
  /// (there is no in-app OTP-code endpoint); this resends that link.
  Future<void> resendVerificationEmail() async {
    await ApiClient.instance
        .post<Map<String, dynamic>>(ApiConstants.resendVerification);
  }

  // ── Forgot password ───────────────────────────────────────────────────────────
  /// POST /auth/password/forgot
  Future<void> forgotPassword({required String email}) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
  }

  // ── Reset password ────────────────────────────────────────────────────────────
  /// POST /auth/password/reset
  /// The backend consumes the [token] emailed to the user (Laravel's
  /// password-broker token), not an OTP code — [token] must come from the
  /// link the user received by email.
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.resetPassword,
      data: {
        'email': email,
        'token': token,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────────
  /// POST /auth/logout
  Future<void> logout() async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.logout,
    );
  }

  // ── Response parser ───────────────────────────────────────────────────────────

  AuthResult _parseAuthResult(Map<String, dynamic> raw) {
    // Backend shape: { data: { user, token, store? } }. `store` is only
    // present on merchant registration — merge its id/name into the user
    // JSON so AppUser.fromServerJson (which reads store_id/store_name off
    // the user object) picks them up immediately, without waiting for the
    // next GET /profile.
    final body =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;

    // Defensive parse: user must be a Map, token must be a String.
    final rawUser = body['user'];
    if (rawUser is! Map) {
      throw const UnknownException('Unexpected auth response: missing user object.');
    }
    final userJson = Map<String, dynamic>.from(rawUser);

    final rawToken = body['token'];
    if (rawToken == null || rawToken.toString().isEmpty) {
      throw const UnknownException('Unexpected auth response: missing token.');
    }

    final storeJson = body['store'];
    if (storeJson is Map) {
      userJson['store_id'] = storeJson['id']?.toString();
      userJson['store_name'] = (storeJson['store_name'] ?? storeJson['name'])?.toString();
    }
    return AuthResult(
      user: AppUser.fromServerJson(userJson),
      tokens: AuthTokens(
        accessToken: rawToken.toString(),
      ),
    );
  }

  /// Exposes the auth-envelope parser to focused tests without exposing any
  /// network or authentication state.
  static AuthResult parseAuthResultForTesting(Map<String, dynamic> raw) {
    return AuthService._()._parseAuthResult(raw);
  }
}
