import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/admin_dashboard_model.dart';

/// Reads the system-wide overview available to admin users.
class AdminDashboardService {
  AdminDashboardService._();

  static final AdminDashboardService instance = AdminDashboardService._();

  /// GET /admin/dashboard
  Future<AdminDashboardModel> getDashboard() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.adminDashboard);
    final raw = response.data;
    if (raw == null) {
      throw const FormatException('Admin dashboard response was empty.');
    }

    final data = raw['data'];
    if (data is! Map) {
      throw const FormatException('Admin dashboard data was malformed.');
    }

    return AdminDashboardModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }
}
