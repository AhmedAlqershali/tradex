import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/admin_analytics_model.dart';

/// Reads the fixed, last-12-month analytics exposed by the admin API.
class AdminAnalyticsService {
  AdminAnalyticsService._();

  static final AdminAnalyticsService instance = AdminAnalyticsService._();

  /// GET /admin/analytics. The backend does not accept filters or ranges.
  Future<AdminAnalyticsModel> getAnalytics() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.adminAnalytics);
    final raw = response.data;
    if (raw == null) {
      throw const FormatException('Admin analytics response was empty.');
    }

    final data = raw['data'];
    if (data is! Map) {
      throw const FormatException('Admin analytics data was malformed.');
    }

    return AdminAnalyticsModel.fromJson(Map<String, dynamic>.from(data));
  }
}
