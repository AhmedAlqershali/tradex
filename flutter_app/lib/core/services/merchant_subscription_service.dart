import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/admin_subscription_model.dart';

/// Reads the authenticated merchant's current trial or paid subscription.
///
/// Subscription changes remain an admin/backend responsibility. This client
/// only consumes the existing GET /merchant/subscription endpoint.
class MerchantSubscriptionService {
  MerchantSubscriptionService._();

  static final MerchantSubscriptionService instance =
      MerchantSubscriptionService._();

  Future<AdminSubscription?> getCurrentSubscription() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.merchantSubscription);
    final raw = response.data;
    final data = raw?['data'];

    if (data == null) return null;
    if (data is! Map) {
      throw const FormatException('Merchant subscription data was malformed.');
    }

    return AdminSubscription.fromJson(Map<String, dynamic>.from(data));
  }
}
