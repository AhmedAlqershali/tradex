import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/admin_product_model.dart';
import 'package:ai_saas/shared/models/product_model.dart';

class AdminProductService {
  AdminProductService._();

  static final AdminProductService instance = AdminProductService._();

  Future<AdminProductPage> listProducts({
    String? search,
    String? status,
    int? categoryId,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (categoryId != null) 'category_id': categoryId,
    };
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.adminProducts,
      queryParameters: query,
    );
    final body = _map(_map(response.data)['data']);
    final products = _list(body['data'])
        .map(Product.fromServerJson)
        .toList(growable: false);
    return AdminProductPage(
      products: products,
      pagination: AdminProductPagination.fromJson(_map(body['pagination'])),
    );
  }

  Future<Product> getProduct(String id) async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.adminProductById(id));
    return Product.fromServerJson(_map(_map(response.data)['data']));
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
