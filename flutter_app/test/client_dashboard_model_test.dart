import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/shared/models/client_dashboard_model.dart';

void main() {
  test('parses client dashboard counters', () {
    final dashboard = ClientDashboardModel.fromJson({
      'orders_count': 4,
      'favorites_count': 7,
    });

    expect(dashboard.ordersCount, 4);
    expect(dashboard.favoritesCount, 7);
  });

  test('missing client dashboard counters default to zero', () {
    final dashboard = ClientDashboardModel.fromJson({});

    expect(dashboard.ordersCount, 0);
    expect(dashboard.favoritesCount, 0);
  });
}
