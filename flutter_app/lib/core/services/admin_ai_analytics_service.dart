import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/admin_ai_insight_model.dart';

class AdminAiAnalyticsService {
  AdminAiAnalyticsService._();

  static final AdminAiAnalyticsService instance = AdminAiAnalyticsService._();

  Future<AdminAiInsight> generate({
    String type = 'overview',
    int periodDays = 30,
    String language = 'Arabic',
  }) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.aiAnalytics,
      queryParameters: {
        'type': type,
        'period_days': periodDays,
        'language': language,
      },
    );
    final body = response.data;
    final data = body?['data'];
    if (data is! Map) {
      throw const FormatException('AI analytics response was malformed.');
    }
    return AdminAiInsight.fromJson(Map<String, dynamic>.from(data));
  }
}
