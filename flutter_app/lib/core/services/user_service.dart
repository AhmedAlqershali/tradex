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
    return parseProfileResponse(response.data!);
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
    return parseProfileResponse(response.data!);
  }

  // ── Upload avatar ─────────────────────────────────────────────────────────────
  /// POST /profile/avatar
  /// [filePath] — absolute path from the image picker.
  /// Returns the authoritative profile returned by Laravel, including the
  /// hosted avatar URL.
  Future<AppUser> uploadAvatar({required String filePath}) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });
    final response = await ApiClient.instance
        .postFormData<Map<String, dynamic>>(ApiConstants.meAvatar, formData);
    final user = parseProfileResponse(response.data!);
    if (user.photoPath == null) {
      throw const UnknownException(
        'تم رفع الصورة لكن لم يُرجع الخادم بيانات الصورة.',
      );
    }
    return user;
  }

  /// Extracts the authoritative user object from either the standard
  /// `{data: {...}}` envelope or a flat response.
  static AppUser parseProfileResponse(Map<String, dynamic> raw) {
    final userJson = raw['data'] is Map
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : raw;
    return AppUser.fromServerJson(userJson);
  }

  /// Exposed for contract tests without making a network request.
  static AppUser parseProfileResponseForTesting(Map<String, dynamic> raw) =>
      parseProfileResponse(raw);

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
