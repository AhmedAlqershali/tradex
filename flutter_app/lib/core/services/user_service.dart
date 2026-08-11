import 'package:dio/dio.dart';
import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/shared/users/user_model.dart';

// ─── UserService ──────────────────────────────────────────────────────────────
//
// Handles user profile API calls.
//
// Endpoints:
//   GET  /profile
//   PUT  /profile
//   POST /profile/avatar
// ─────────────────────────────────────────────────────────────────────────────

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  // ── Get profile ───────────────────────────────────────────────────────────────
  /// GET /profile
  Future<AppUser> getMe() async {
    final response =
        await ApiClient.instance.get<Map<String, dynamic>>(ApiConstants.me);
    final raw = response.data!;
    final userJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return AppUser.fromServerJson(userJson);
  }

  // ── Update profile ────────────────────────────────────────────────────────────
  /// PUT /profile
  Future<AppUser> updateMe({
    String? name,
    String? email,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;

    final response = await ApiClient.instance
        .put<Map<String, dynamic>>(ApiConstants.me, data: body);
    final raw = response.data!;
    final userJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return AppUser.fromServerJson(userJson);
  }

  // ── Upload avatar ─────────────────────────────────────────────────────────────
  /// POST /profile/avatar
  /// [filePath] — absolute path from the image picker.
  /// Returns the hosted avatar URL.
  Future<String> uploadAvatar({required String filePath}) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });
    final response = await ApiClient.instance
        .postFormData<Map<String, dynamic>>(ApiConstants.meAvatar, formData);
    final raw = response.data!;
    final body = raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    // ProfileService::userPayload() returns the resolved Storage URL under
    // the 'avatar' key — the other keys are kept as a defensive fallback.
    final avatar = body['avatar'] as String? ??
        body['avatar_url'] as String? ??
        body['url'] as String? ??
        body['avatarUrl'] as String?;
    if (avatar == null || avatar.trim().isEmpty) {
      throw const UnknownException(
        'تم رفع الصورة لكن لم يُرجع الخادم رابط الصورة.',
      );
    }
    return avatar;
  }

  /// PUT /profile/password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      ApiConstants.mePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      },
    );
  }
}
