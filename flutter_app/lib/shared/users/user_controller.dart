import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/auth_service.dart';
import 'package:ai_saas/core/services/firebase_email_verification_service.dart';
import 'package:ai_saas/core/services/store_service.dart';
import 'package:ai_saas/core/services/user_service.dart';
import 'package:ai_saas/core/storage/secure_storage_service.dart';
import 'avatar_diagnostics.dart';
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
//   - loadSession() restores only a server-validated Sanctum token.
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

  // Incremented when a profile mutation starts. A refresh captures the
  // current value before awaiting /auth/me and only publishes its result when
  // the value is unchanged.
  int _profileGeneration = 0;
  String? _pendingVerificationPassword;

  Future<AppUser?> loadPendingEmailVerification() async {
    final userJson = await SecureStorageService.instance
        .readPendingVerificationUser();
    if (userJson == null || userJson.isEmpty) return null;
    try {
      final user = AppUser.fromJson(
        Map<String, dynamic>.from(jsonDecode(userJson) as Map),
      );
      _pendingVerificationPassword = await SecureStorageService.instance
          .readPendingVerificationPassword();
      if (_pendingVerificationPassword == null) {
        await SecureStorageService.instance.clearPendingVerification();
        return null;
      }
      currentUserNotifier.value = user;
      return user;
    } catch (_) {
      await SecureStorageService.instance.clearPendingVerification();
      return null;
    }
  }

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
  ///   1. SecureStorage token → GET /auth/me (server-authoritative path)
  ///   2. null → navigate to onboarding
  ///
  /// Session validation failures fail closed rather than restoring a local
  /// identity without server confirmation.
  Future<AppUser?> loadSession({
    Future<AppUser> Function()? fetchCurrentUser,
  }) async {
    try {
      final token = await SecureStorageService.instance.readAccessToken();
      if (token != null && token.isNotEmpty) {
        final user =
            await (fetchCurrentUser ?? AuthService.instance.getCurrentUser)();
        currentUserNotifier.value = user;
        AvatarDiagnostics.log('currentUserNotifier session restore', user.photoPath);
        return user;
      }
    } on AuthException {
      // A 401 is the one restoration failure that proves the stored Sanctum
      // credential is no longer valid. ApiClient also clears the token for
      // real HTTP 401 responses; keep this branch explicit for the injected
      // restoration seam and for direct callers.
      await SecureStorageService.instance.clearAll();
      await _clearLegacySession();
      currentUserNotifier.value = null;
      authErrorNotifier.value = 'انتهت جلستك. يرجى تسجيل الدخول مجدداً.';
      return null;
    } on ApiException catch (e) {
      // A server, authorization, validation, network, or timeout failure does
      // not prove that the stored credential is invalid. Preserve it so a
      // later request or app restart can retry /auth/me.
      await _clearLegacySession();
      currentUserNotifier.value = null;
      authErrorNotifier.value = _localiseError(e);
      return null;
    } catch (e) {
      // Do not discard a credential merely because this restoration attempt
      // failed outside the typed API error hierarchy.
      await _clearLegacySession();
      currentUserNotifier.value = null;
      debugPrint('UserController.loadSession failed closed: $e');
      return null;
    }

    // Legacy identity data is no longer an authentication mechanism. Remove it
    // so a tampered or stale SharedPreferences record cannot restore access
    // without a server-validated Sanctum token.
    await _clearLegacySession();
    currentUserNotifier.value = null;
    return null;
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
      if (result.tokens.accessToken.isNotEmpty) {
        await _storeTokens(result.tokens);
      }
      currentUserNotifier.value = result.user;
      AvatarDiagnostics.log('currentUserNotifier login', result.user.photoPath);
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
    var firebaseUserCreated = false;
    try {
      firebaseUserCreated = await FirebaseEmailVerificationService.instance.registerAndSend(
        email: email,
        password: password,
      );
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
      _pendingVerificationPassword = password;
      await SecureStorageService.instance.savePendingVerification(
        userJson: jsonEncode(result.user.toJson()),
        password: password,
      );
      if (result.tokens.accessToken.isNotEmpty) {
        await _storeTokens(result.tokens);
      }
      currentUserNotifier.value = result.user;
      await _clearLegacySession();
      return result.user;
    } on ApiException catch (e) {
      if (firebaseUserCreated) {
        await FirebaseEmailVerificationService.instance.deleteCurrentUser();
      }
      await SecureStorageService.instance.clearPendingVerification();
      authErrorNotifier.value = _localiseError(e);
      rethrow;
    } catch (e) {
      if (firebaseUserCreated) {
        await FirebaseEmailVerificationService.instance.deleteCurrentUser();
      }
      await SecureStorageService.instance.clearPendingVerification();
      rethrow;
    } finally {
      _end();
    }
  }

  Future<AppUser> loginPendingVerification({
    required String email,
    required AppType role,
  }) async {
    final password = _pendingVerificationPassword;
    if (password == null) {
      throw const AuthException('Registration credentials are no longer available.');
    }
    try {
      final user = await login(email: email, password: password, role: role);
      await SecureStorageService.instance.clearPendingVerification();
      return user;
    } finally {
      _pendingVerificationPassword = null;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────────

  /// POST /auth/logout (best-effort) then clears all local state.
  ///
  /// [performLogout] is a test seam for verifying session isolation without
  /// making a network request. Production callers use AuthService by default.
  Future<void> logout({Future<void> Function()? performLogout}) async {
    _begin();
    try {
      await (performLogout ?? AuthService.instance.logout)();
    } catch (_) {
      // Always clear local state even when the server call fails.
    } finally {
      _pendingVerificationPassword = null;
      await SecureStorageService.instance.clearPendingVerification();
      await FirebaseEmailVerificationService.instance.signOut();
      await SecureStorageService.instance.clearAll();
      await _clearLegacySession();
      currentUserNotifier.value = null;
      authErrorNotifier.value = null;
      _end();
    }
  }

  /// DELETE /profile (self-service account deletion).
  /// Only clear local auth state when the server confirms the account is gone.
  Future<void> deleteAccount({Future<void> Function()? performDelete}) async {
    isLoadingNotifier.value = true;
    try {
      await (performDelete ?? UserService.instance.deleteAccount)();
      await SecureStorageService.instance.deleteAccessToken();
      await SecureStorageService.instance.deleteRefreshToken();
      await _clearLegacySession();
      currentUserNotifier.value = null;
      authErrorNotifier.value = null;
    } finally {
      isLoadingNotifier.value = false;
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

  // ── Profile mutations ─────────────────────────────────────────────────────────

  /// Stores an already-constructed [AppUser] directly.
  Future<void> setUser(AppUser user) async {
    currentUserNotifier.value = user;
    AvatarDiagnostics.log('currentUserNotifier setUser', user.photoPath);
  }

  /// Refreshes the authenticated profile from Laravel.
  ///
  /// The server response is authoritative, including the avatar URL. This is
  /// used by screens that need to reflect profile changes made outside the
  /// current Flutter process.
  Future<void> refreshProfile() async {
    await refreshProfileIfCurrent();
  }

  /// Refreshes the authenticated profile and ignores a response made stale by
  /// a profile mutation that started while the request was in flight.
  ///
  /// A nullable result distinguishes an intentionally ignored response from a
  /// successfully applied profile. The optional fetcher keeps this
  /// synchronization boundary straightforward to test without changing the
  /// production service path.
  Future<AppUser?> refreshProfileIfCurrent({
    Future<AppUser> Function()? fetchCurrentUser,
  }) async {
    final generation = _profileGeneration;
    final user =
        await (fetchCurrentUser ?? UserService.instance.getMe)();
    if (generation != _profileGeneration) return null;
    currentUserNotifier.value = user;
    AvatarDiagnostics.log('currentUserNotifier refreshProfile', user.photoPath);
    return user;
  }

  /// Updates mutable profile fields via PUT /profile.
  ///
  /// If [photoPath] is a local file path, it is uploaded first via
  /// POST /profile/avatar. Only Laravel's returned server URL is stored in the
  /// user model; the picked device path is never a permanent avatar value.
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? region,
    String? photoPath,
  }) async {
    _begin();
    _invalidateProfileRefreshes();
    try {
      // Upload avatar first if a new local file path was provided. The upload
      // response contains the complete authoritative user, not just a URL.
      AppUser? updated;
      String? uploadedPhotoPath;
      if (photoPath != null &&
          !AppUser.isServerPhotoPath(photoPath)) {
        updated = await UserService.instance.uploadAvatar(filePath: photoPath);
        uploadedPhotoPath = updated.photoPath;
        AvatarDiagnostics.log('avatar upload response', uploadedPhotoPath);
        AvatarDiagnostics.logState(
          'immediately_after_upload',
          updated.photoPath,
        );
      }

      // Update text fields on the server when at least one is provided.
      if (name != null || email != null || phone != null || region != null) {
        final profileUpdated = await UserService.instance.updateMe(
          name: name,
          email: email,
          phone: phone,
          region: region,
        );
        // The upload response is authoritative for this mutation. Do not let
        // a concurrent or stale second response erase the fresh avatar URL.
        updated = mergeProfileMutationResults(
          profileUpdated: profileUpdated,
          uploadedPhotoPath: uploadedPhotoPath,
        );
        AvatarDiagnostics.log('profile update response', profileUpdated.photoPath);
      }

      final current = currentUserNotifier.value;
      if (updated != null) {
        currentUserNotifier.value =
            updated.copyWith(region: region ?? current?.region);
        AvatarDiagnostics.log(
          'currentUserNotifier profile mutation',
          currentUserNotifier.value?.photoPath,
        );
        AvatarDiagnostics.logState(
          'after_profile_mutation',
          currentUserNotifier.value?.photoPath,
        );
      } else if (current != null) {
        currentUserNotifier.value = current.copyWith(
          email: email,
          region: region,
        );
      }
    } on ApiException catch (e) {
      authErrorNotifier.value = _localiseError(e);
      rethrow;
    } finally {
      _end();
    }
  }

  /// Keeps the avatar returned by the upload call when a follow-up profile
  /// response does not contain the just-uploaded value.
  @visibleForTesting
  static AppUser mergeProfileMutationResults({
    required AppUser profileUpdated,
    required String? uploadedPhotoPath,
  }) {
    if (uploadedPhotoPath == null) return profileUpdated;
    return profileUpdated.copyWith(photoPath: uploadedPhotoPath);
  }

  /// Persists a GPS-resolved or manually selected location through Laravel.
  /// The returned profile is authoritative and replaces the local notifier.
  Future<void> updateLocation({
    required String? region,
    required String? locationName,
    required double? latitude,
    required double? longitude,
  }) async {
    _begin();
    _invalidateProfileRefreshes();
    try {
      final updated = await UserService.instance.updateLocation(
        region: region,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
      );
      currentUserNotifier.value = updated;
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
    _invalidateProfileRefreshes();
    try {
      final storeId = currentUserNotifier.value?.storeId;
      if (storeId == null || storeId.isEmpty) {
        throw const UnknownException(
          'Merchant store was not created during registration.',
        );
      }

      // Upload logo if a new local file path was provided.
      if (logoPath != null &&
          !logoPath.startsWith('http://') &&
          !logoPath.startsWith('https://')) {
        await StoreService.instance.uploadStoreLogo(
          storeId: storeId,
          filePath: logoPath,
        );
      }

      // Persist store details on the server.
      final store = await StoreService.instance.updateMyStore(
        storeId: storeId,
        name: storeName.isNotEmpty ? storeName : 'متجري',
        region: region,
      );

      // Update local user state with the confirmed store info.
      final existing = currentUserNotifier.value;
      if (existing != null) {
        currentUserNotifier.value = existing.copyWith(
          storeName: store.title.isNotEmpty ? store.title : storeName,
          storeId:
              (store.id?.isNotEmpty ?? false) ? store.id : existing.storeId,
          storeCategory: storeCategory,
          region: region,
          // Store logo is a store field, never the user's profile avatar.
          photoPath: existing.photoPath,
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

  void _invalidateProfileRefreshes() {
    _profileGeneration++;
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
    if (e is AuthException) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    }
    if (e is ForbiddenException) {
      return e.message;
    }
    if (e is NetworkException) {
      return 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.';
    }
    if (e is TimeoutException) return 'انتهت مهلة الاتصال. حاول مرة أخرى.';
    if (e is ServerException) return 'حدث خطأ في الخادم. حاول لاحقاً.';
    return e.message;
  }

  // ── Legacy session cleanup ───────────────────────────────────────────────────

  Future<void> _clearLegacySession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (_) {}
  }
}
