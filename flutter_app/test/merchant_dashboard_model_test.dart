import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/shared/models/merchant_dashboard_model.dart';

void main() {
  test('parses merchant dashboard summary and collections', () {
    final dashboard = MerchantDashboardModel.fromJson({
      'products': {
        'total': 12,
        'active': 10,
        'out_of_stock': 1,
        'low_stock': 2,
      },
      'orders': {
        'total': 8,
        'pending_review': 3,
        'confirmed': 1,
        'completed': 4,
        'cancelled': 0,
      },
      'total_sales': 1250.5,
      'recent_orders': [
        {
          'id': 42,
          'status': 'pending_review',
          'customer_name': 'Client',
          'total_amount': 100,
        },
      ],
      'top_products': [
        {
          'id': 7,
          'name': 'Product',
          'quantity': 20,
          'status': 'active',
          'price': 25.5,
        },
      ],
      'low_inventory': [],
    });

    expect(dashboard.products.total, 12);
    expect(dashboard.orders.pendingReview, 3);
    expect(dashboard.orders.confirmed, 1);
    expect(dashboard.orders.completed, 4);
    expect(dashboard.totalSales, 1250.5);
    expect(dashboard.recentOrders.single.customerName, 'Client');
    expect(dashboard.topProducts.single.price, 25.5);
    expect(dashboard.isEmpty, isFalse);
  });

  test('missing dashboard values produce safe empty defaults', () {
    final dashboard = MerchantDashboardModel.fromJson({});

    expect(dashboard.products.total, 0);
    expect(dashboard.orders.total, 0);
    expect(dashboard.recentOrders, isEmpty);
    expect(dashboard.lowInventory, isEmpty);
    expect(dashboard.isEmpty, isTrue);
  });
}