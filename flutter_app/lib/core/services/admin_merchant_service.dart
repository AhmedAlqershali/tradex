import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/admin_merchant_model.dart';

class AdminMerchantService {
  AdminMerchantService._();

  static final AdminMerchantService instance = AdminMerchantService._();

  Future<AdminMerchantPage> listMerchants({
    String? search,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.adminStores,
      queryParameters: query,
    );
    final raw = _map(_map(response.data)['data']);
    return AdminMerchantPage(
      merchants: _list(raw['data']).map(AdminMerchant.fromJson).toList(),
      pagination:
          AdminMerchantPagination.fromJson(_map(raw['pagination'])),
    );
  }

  Future<AdminMerchant> getMerchant(String id) async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.adminStoreById(id));
    return AdminMerchant.fromJson(_map(_map(response.data)['data']));
  }

  Future<AdminMerchant> updateStatus(String id, String status) async {
    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      ApiConstants.adminStoreStatus(id),
      data: {'status': status},
    );
    return AdminMerchant.fromJson(_map(_map(response.data)['data']));
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}