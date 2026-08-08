import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/admin_plan_model.dart';

class AdminPlanService {
  AdminPlanService._();

  static final AdminPlanService instance = AdminPlanService._();

  Future<AdminPlanPage> listPlans({
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
      ApiConstants.adminPlans,
      queryParameters: query,
    );
    final body = _map(response.data);
    final data = _map(body['data']);
    return AdminPlanPage(
      plans: _list(data['data']).map(AdminPlan.fromJson).toList(),
      pagination: AdminPlanPagination.fromJson(_map(data['pagination'])),
    );
  }

  Future<AdminPlan> getPlan(String id) async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.adminPlanById(id));
    return AdminPlan.fromJson(_map(_map(response.data)['data']));
  }

  Future<AdminPlan> createPlan({
    required String name,
    required String displayName,
    required double monthlyPrice,
    required double yearlyPrice,
    int? aiUsageLimit,
    int? productLimit,
    required int storeLimit,
    required List<String> features,
    required String status,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.adminPlans,
      data: _payload(
        name: name,
        displayName: displayName,
        monthlyPrice: monthlyPrice,
        yearlyPrice: yearlyPrice,
        aiUsageLimit: aiUsageLimit,
        productLimit: productLimit,
        storeLimit: storeLimit,
        features: features,
        status: status,
      ),
    );
    return AdminPlan.fromJson(_map(_map(response.data)['data']));
  }

  Future<AdminPlan> updatePlan({
    required String id,
    String? name,
    String? displayName,
    double? monthlyPrice,
    double? yearlyPrice,
    int? aiUsageLimit,
    int? productLimit,
    int? storeLimit,
    List<String>? features,
    String? status,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (monthlyPrice != null) 'monthly_price': monthlyPrice,
      if (yearlyPrice != null) 'yearly_price': yearlyPrice,
      if (aiUsageLimit != null) 'ai_usage_limit': aiUsageLimit,
      if (productLimit != null) 'product_limit': productLimit,
      if (storeLimit != null) 'store_limit': storeLimit,
      if (features != null) 'features': features,
      if (status != null) 'status': status,
    };
    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      ApiConstants.adminPlanById(id),
      data: data,
    );
    return AdminPlan.fromJson(_map(_map(response.data)['data']));
  }

  Future<void> deletePlan(String id) async {
    await ApiClient.instance
        .delete<Map<String, dynamic>>(ApiConstants.adminPlanById(id));
  }

  Map<String, dynamic> _payload({
    required String name,
    required String displayName,
    required double monthlyPrice,
    required double yearlyPrice,
    required int? aiUsageLimit,
    required int? productLimit,
    required int storeLimit,
    required List<String> features,
    required String status,
  }) {
    return {
      'name': name,
      'display_name': displayName,
      'monthly_price': monthlyPrice,
      'yearly_price': yearlyPrice,
      if (aiUsageLimit != null) 'ai_usage_limit': aiUsageLimit,
      if (productLimit != null) 'product_limit': productLimit,
      'store_limit': storeLimit,
      'features': features,
      'status': status,
    };
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
