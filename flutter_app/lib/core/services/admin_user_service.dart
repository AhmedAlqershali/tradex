import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/admin_user_model.dart';

class AdminUserService {
  AdminUserService._();

  static final AdminUserService instance = AdminUserService._();

  Future<AdminUserPage> listUsers({
    String? search,
    String? role,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (role != null && role.isNotEmpty) 'role': role,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.adminUsers,
      queryParameters: query,
    );
    final raw = _body(response.data);
    final users = _list(raw['data']).map(AdminUser.fromJson).toList();
    return AdminUserPage(
      users: users,
      pagination: AdminUserPagination.fromJson(_map(raw['pagination'])),
    );
  }

  Future<AdminUser> getUser(String id) async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.adminUserById(id));
    return AdminUser.fromJson(_map(_body(response.data)['data']));
  }

  Future<AdminUser> updateRole(String id, String role) async {
    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      ApiConstants.adminUserRole(id),
      data: {'role': role},
    );
    return AdminUser.fromJson(_map(_body(response.data)['data']));
  }

  Future<AdminUser> updateStatus(String id, String status) async {
    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      ApiConstants.adminUserStatus(id),
      data: {'status': status},
    );
    return AdminUser.fromJson(_map(_body(response.data)['data']));
  }

  Future<void> deleteUser(String id) async {
    await ApiClient.instance
        .delete<Map<String, dynamic>>(ApiConstants.adminUserById(id));
  }

  Map<String, dynamic> _body(Map<String, dynamic>? value) => value ?? const {};

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
