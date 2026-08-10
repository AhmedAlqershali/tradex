import 'package:dio/dio.dart';

import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/admin_category_model.dart';

class AdminCategoryService {
  AdminCategoryService._();

  static final AdminCategoryService instance = AdminCategoryService._();

  Future<AdminCategoryPage> listCategories({
    String? search,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.adminCategories,
      queryParameters: query,
    );
    final raw = _map(_map(response.data)['data']);
    return AdminCategoryPage(
      categories: _list(raw['data']).map(AdminCategory.fromJson).toList(),
      pagination: AdminCategoryPagination.fromJson(_map(raw['pagination'])),
    );
  }

  Future<AdminCategory> getCategory(String id) async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.adminCategoryById(id));
    return AdminCategory.fromJson(_map(_map(response.data)['data']));
  }

  Future<AdminCategory> createCategory({
    required String name,
    required String status,
    String? imagePath,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'status': status,
      if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
    });
    final response =
        await ApiClient.instance.postFormData<Map<String, dynamic>>(
      ApiConstants.adminCategories,
      formData,
    );
    return AdminCategory.fromJson(_map(_map(response.data)['data']));
  }

  Future<AdminCategory> updateCategory({
    required String id,
    String? name,
    String? status,
    String? imagePath,
  }) async {
    final formData = FormData.fromMap({
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (imagePath != null) 'image': await MultipartFile.fromFile(imagePath),
    });
    // PHP does not populate multipart fields for a native PUT request.
    // Laravel's standard _method override preserves the backend's PUT route
    // while allowing the optional image upload to be parsed correctly.
    formData.fields.add(const MapEntry('_method', 'PUT'));
    final response =
        await ApiClient.instance.postFormData<Map<String, dynamic>>(
      ApiConstants.adminCategoryById(id),
      formData,
    );
    return AdminCategory.fromJson(_map(_map(response.data)['data']));
  }

  Future<void> deleteCategory(String id) async {
    await ApiClient.instance
        .delete<Map<String, dynamic>>(ApiConstants.adminCategoryById(id));
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
