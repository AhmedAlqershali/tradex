import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/merchant_dashboard_model.dart';

/// Reads the authenticated merchant's dashboard summary.
class MerchantDashboardService {
  MerchantDashboardService._();

  static final MerchantDashboardService instance =
      MerchantDashboardService._();

  /// GET /merchant/dashboard
  Future<MerchantDashboardModel> getDashboard() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.merchantDashboard);
    final raw = response.data;
    if (raw == null || raw['data'] is! Map) {
      throw const FormatException('Merchant dashboard data was malformed.');
    }

    return MerchantDashboardModel.fromJson(
      Map<String, dynamic>.from(raw['data'] as Map),
    );
  }
}