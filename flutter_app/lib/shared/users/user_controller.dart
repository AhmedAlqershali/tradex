import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/auth_service.dart';
import 'package:ai_saas/core/services/store_service.dart';
import 'package:ai_saas/core/services/user_service.dart';
import 'package:ai_saas/core/storage/secure_storage_service.dart';
import 'user_model.dart';

// ─── UserController ───────────────────────────────────────────────────────────
//
// Singleton user-identity controller. Follows the ValueNotifier singleton
// pattern used by ProductController, OrderController, etc.
//
// Phase B — real JWT auth:
//   - login / startRegistration / logout / forgotPassword / verifyOtp /
//     resetPassword all make real API calls via AuthService.
//   - Tokens are stored in SecureStorageService (flutter_secure_storage).
//   - loadSession() tries the stored JWT first; falls back to the legacy
//     SharedPreferences session during the transition period.
//
// Profile mutations (UserService):
//   - updateProfile → PUT /profile
//   - completeMerchantProfile → PUT /merchants/me/store
// ─────────────────────────────────────────────────────────────────────────────

class UserController {
  UserController._();
  static final UserController instance = UserController._();

  // Legacy key kept for migration from the SharedPreferences phase.
  static const String _sessionKey = 'tradex_user_session';

  // ── Public notifiers ──────────────────────────────────────────────────────────

  /// The currently signed-in user. Null when no session exists.
  final ValueNotifier<AppUser?> currentUserNotifier = ValueNotifier(null);

  /// True while any auth operation is in progress.
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  /// Contains a human-readable error message after a failed auth call.
  /// Reset to null at the start of each new call.
  final ValueNotifier<String?> authErrorNotifier = ValueNotifier(null);

  AppUser? get currentUser => currentUserNotifier.value;

  // ── Session-expired hook (called by ApiClient on 401 refresh failure) ─────────

  /// Invoked by [ApiClient] via the callback registered in main.dart.
  /// Clears state so the next navigation check sends the user back to login.
  void onTokenExpired() {
    currentUserNotifier.value = null;
    authErrorNotifier.value = 'انتهت جلستك. يرجى تسجيل الدخول مجدداً.';
    unawaited(_clearLegacySession());
  }

  // ── Session restore ───────────────────────────────────────────────────────────

  /// Called at app start (SplashScreen).
  ///
  /// Priority:
  ///   1. SecureStorage token → GET /profile (Phase B live path)
  ///   2. SharedPreferences session (legacy migration path)
  ///   3. null → navigate to onboarding
  ///
  /// Network errors on the splash screen degrade gracefully to the legacy path
  /// rather than blocking the user.
  Future<AppUser?> loadSession() async {
    try {
      final token = await SecureStorageService.instance.readAccessToken();
      if (token != null && token.isNotEmpty) {
        final user = await AuthService.instance.getCurrentUser();
        currentUserNotifier.value = user;
        return user;
      }
    } on ApiException {
      // A stored token is authoritative only after the server validates it.
      // Never fall back to the legacy local session after a failed validation:
      // that would keep the UI authenticated without a valid Sanctum token.
      await SecureStorageService.instance.clearAll();
      await _clearLegacySession();
      currentUserNotifier.value = null;
      return null;
    } catch (e) {
      // Storage/parsing failures must also fail closed. Do not restore a
      // locally cached identity when a stored server session could not be
      // validated.
      await SecureStorageService.instance.clearAll();
      await _clearLegacySession();
      currentUserNotifier.value = null;
      debugPrint('UserController.loadSession failed closed: $e');
      return null;
    }

    // No secure token exists. A legacy session is used only as a migration
    // path for installations that predate the Sanctum-backed flow.
    return _loadLegacySession();
  }

  // ── Login ─────────────────────────────────────────────────────────────────────

  /// POST /auth/login
  ///
  /// [role] is kept in the signature for backward compatibility with screens.
  /// The authoritative role is returned by the server.
  Future<AppUser> login({
    required String email,
    required String password,
    required AppType role,
  }) async {
    _begin();
    try {
      final result = await AuthService.instance.login(
        email: email,
        password: password,
      );
      await _storeTokens(result.tokens);
      currentUserNotifier.value = result.user;
      await _clearLegacySession();
      return result.user;
    } on ApiException catch (e) {
      authErrorNotifier.value = _localiseError(e);
      rethrow;
    } finally {
      _end();
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────────

  /// POST /auth/register/client or /auth/register/merchant.
  ///
  /// The backend requires a store name at merchant-registration time (the
  /// store row is created atomically with the user). This screen's flow
  /// collects the real store name afterwards in
  /// [CompleteProfileMerchantScreen], so a placeholder is sent here and then
  /// overwritten by [completeMerchantProfile] once the merchant submits it —
  /// no UI change needed for either step.
  Future<AppUser> startRegistration({
    required String name,
    required String email,
    required String phone,
    required String password,
    required AppType role,
  }) async {
    _begin();
    try {
      final result = role == AppType.merchant
          ? await AuthService.instance.registerMerchant(
              name: name,
              email: email,
              phone: phone,
              password: password,
              storeName: 'متجر $name',
            )
          : await AuthService.instance.registerClient(
              name: name,
              email: email,
              phone: phone,
              password: password,
            );
      await _storeTokens(result.tokens);
      currentUserNotifier.value = result.user;
      await _clearLegacySession();
      return result.user;
    } on ApiException catch (e) {
      authErrorNotifier.value = _localiseError(e);
      rethrow;
    } finally {
      _end();
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────────

  /// POST /auth/logout (best-effort) then clears all local state.
  Future<void> logout() async {
    _begin();
    try {
      await AuthService.instance.logout();
    } catch (_) {
      // Always clear local state even when the server call fails.
    } finally {
      await SecureStorageService.instance.clearAll();
      await _clearLegacySession();
      currentUserNotifier.value = null;
      authErrorNotifier.value = null;
      _end();
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────────

  /// POST /auth/forgot-password
  Future<void> forgotPassword({required String email}) async {
    _begin();
    try {
      await AuthService.instance.forgotPassword(email: email);
    } on ApiException catch (e) {
      authErrorNotifier.value = _localiseError(e);
      rethrow;
    } finally {
      _end();
    }
  }

  // ── Email verification ────────────────────────────────────────────────────────

  /// The backend uses a signed emailed link for email verification — there is
  /// no in-app OTP-code endpoint. For the forgot-password flow the "OTP" the
  /// user enters is the password-reset token from the email link; that token
  /// is validated when POST /auth/password/reset is called (not before).
  /// This method is therefore a deliberate no-op: it succeeds immediately so
  /// [AuthBloc] emits [AuthOtpVerified] and navigates to the new-password
  /// screen, where the real token validation happens.
  /// Kept as a same-signature method so [AuthBloc] doesn't need to change.
  Future<void> verifyOtp({required String email, required String otp}) async {
    // No-op: no pre-validation endpoint exists. The reset token is validated
    // by the backend when resetPassword() is called with it.
  }

  // ── Reset password ────────────────────────────────────────────────────────────

  /// POST /auth/password/reset
  /// The backend expects the password-reset token emailed to the user, not
  /// an OTP code — [otp] is passed straight through as that token. Kept as
  /// the same parameter name so [AuthBloc]/[AuthEvent] don't need to change.
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _begin();
    try {
      await AuthService.instance.resetPassword(
        email: email,
        token: otp,
        newPassword: newPassword,
      );
    } on ApiException catch (e) {
      authErrorNotifier.value = _localiseError(e);
      rethrow;
    } finally {
      _end();
    }
  }

  // ── Profile mutations (Phase C will wire to UserService) ──────────────────────

  /// Stores an already-constructed [AppUser] directly.
  Future<void> setUser(AppUser user) async {
    currentUserNotifier.value = user;
  }

  /// Updates mutable profile fields via PUT /profile.
  ///
  /// If [photoPath] is a local file path (not starting with http), the avatar
  /// is uploaded first via POST /profile/avatar and the returned URL is stored.
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? region,
    String? photoPath,
  }) async {
    _begin();
    try {
      // Upload avatar first if a new local file path was provided.
      String? resolvedPhotoPath = photoPath;
      if (photoPath != null &&
          !photoPath.startsWith('http://') &&
          !photoPath.startsWith('https://')) {
        resolvedPhotoPath =
            await UserService.instance.uploadAvatar(filePath: photoPath);
      }

      // Update text fields on the server when at least one is provided.
      AppUser? updated;
      if (name != null || phone != null || region != null) {
        updated = await UserService.instance.updateMe(
          name: name,
          phone: phone,
          city: region,
        );
      }

      // Merge server response with local overrides.
      final current = currentUserNotifier.value;
      if (updated != null) {
        currentUserNotifier.value = updated.copyWith(
          photoPath: resolvedPhotoPath ?? current?.photoPath,
          // email is not sent/returned by this update call — keep existing value.
          email: email ?? updated.email,
        );
      } else if (current != null) {
        currentUserNotifier.value = current.copyWith(
          email: email,
          photoPath: resolvedPhotoPath,
        );
      }
    } on ApiException catch (e) {
      authErrorNotifier.value = _localiseError(e);
      rethrow;
    } finally {
      _end();
    }
  }

  /// Creates or updates the merchant's store profile via
  /// PUT /merchant/stores/:id.
  ///
  /// If [logoPath] is a local file path (not starting with http), the logo
  /// is uploaded first via POST /merchant/stores/:id/logo.
  ///
  /// [storeCategory] and [region] are kept locally on [AppUser] only — the
  /// backend store record has no category/city fields.
  Future<void> completeMerchantProfile({
    required String storeName,
    String? storeCategory,
    String? region,
    String? logoPath,
  }) async {
    _begin();
    try {
      final storeId = currentUserNotifier.value?.storeId;
      if (storeId == null || storeId.isEmpty) {
        throw const UnknownException(
          'Merchant store was not created during registration.',
        );
      }

      // Upload logo if a new local file path was provided.
      String? resolvedLogoPath = logoPath;
      if (logoPath != null &&
          !logoPath.startsWith('http://') &&
          !logoPath.startsWith('https://')) {
        resolvedLogoPath = await StoreService.instance
            .uploadStoreLogo(storeId: storeId, filePath: logoPath);
      }

      // Persist store details on the server.
      final store = await StoreService.instance.updateMyStore(
        storeId: storeId,
        name: storeName.isNotEmpty ? storeName : 'متجري',
      );

      // Update local user state with the confirmed store info.
      final existing = currentUserNotifier.value;
      if (existing != null) {
        currentUserNotifier.value = existing.copyWith(
          storeName: store.title.isNotEmpty ? store.title : storeName,
          storeId: (store.id?.isNotEmpty ?? false) ? store.id : existing.storeId,
          storeCategory: storeCategory,
          region: region,
          photoPath: resolvedLogoPath ?? existing.photoPath,
        );
      }
    } on ApiException catch (e) {
      authErrorNotifier.value = _localiseError(e);
      rethrow;
    } finally {
      _end();
    }
  }

  /// Ensures a client user object exists. No-op when a JWT user is present.
  /// Phase C: pure no-op when token is valid.
  Future<void> ensureClientUser() async {
    if (currentUserNotifier.value?.isClient == true) return;
    final existing = currentUserNotifier.value;
    currentUserNotifier.value = AppUser(
      id: existing?.id ?? 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: existing?.name ?? 'مستخدم Tradex',
      email: existing?.email ?? '',
      phone: existing?.phone ?? '',
      role: AppType.client,
      region: existing?.region,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────────

  void _begin() {
    isLoadingNotifier.value = true;
    authErrorNotifier.value = null;
  }

  void _end() {
    isLoadingNotifier.value = false;
  }

  Future<void> _storeTokens(AuthTokens tokens) async {
    await SecureStorageService.instance.saveAccessToken(tokens.accessToken);
    // Backend never issues a refresh token — only persist one if a future
    // backend change starts sending it.
    if (tokens.refreshToken != null && tokens.refreshToken!.isNotEmpty) {
      await SecureStorageService.instance
          .saveRefreshToken(tokens.refreshToken!);
    }
  }

  /// Maps [ApiException] subtypes to Arabic user-facing messages.
  String _localiseError(ApiException e) {
    if (e is ValidationException) {
      // Prefer first server validation message if available.
      final first = e.errors.values.firstOrNull?.firstOrNull;
      return first ?? e.message;
    }
    if (e is AuthException) return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    if (e is NetworkException) return 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.';
    if (e is TimeoutException) return 'انتهت مهلة الاتصال. حاول مرة أخرى.';
    if (e is ServerException) return 'حدث خطأ في الخادم. حاول لاحقاً.';
    return e.message;
  }

  // ── Legacy SharedPreferences (migration support) ──────────────────────────────

  Future<AppUser?> _loadLegacySession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      if (raw == null) return null;
      final user = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      currentUserNotifier.value = user;
      return user;
    } catch (e) {
      debugPrint('UserController._loadLegacySession error: $e');
      return null;
    }
  }

  Future<void> _clearLegacySession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (_) {}
  }
}
