import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/client_dashboard_model.dart';

/// Reads the authenticated client's dashboard counters.
class ClientDashboardService {
  ClientDashboardService._();

  static final ClientDashboardService instance = ClientDashboardService._();

  /// GET /client/dashboard
  Future<ClientDashboardModel> getDashboard() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.clientDashboard);
    final raw = response.data;
    if (raw == null || raw['data'] is! Map) {
      throw const FormatException('Client dashboard data was malformed.');
    }

    return ClientDashboardModel.fromJson(
      Map<String, dynamic>.from(raw['data'] as Map),
    );
  }
}
