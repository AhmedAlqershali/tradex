import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/shared/models/admin_analytics_model.dart';

void main() {
  test('parses the supported admin analytics response', () {
    final analytics = AdminAnalyticsModel.fromJson({
      'sales_statistics': {
        'monthly_sales': [
          {'year': 2026, 'month': 8, 'revenue': '1250.50', 'order_count': 4},
        ],
      },
      'order_statistics': {
        'by_status': {
          'pending': 1,
          'confirmed': 2,
          'processing': 3,
          'completed': 4,
          'cancelled': 0,
        },
      },
      'user_growth': [
        {'year': 2026, 'month': 8, 'new_users': 7},
      ],
      'merchant_growth': [
        {'year': 2026, 'month': 8, 'new_merchants': 2},
      ],
      'product_statistics': {
        'by_category': [
          {'category': 'Shoes', 'count': 5},
        ],
        'by_status': {'active': 5, 'inactive': 1, 'out_of_stock': 2},
      },
    });

    expect(analytics.sales.monthlySales.single.revenue, 1250.50);
    expect(analytics.sales.monthlySales.single.orderCount, 4);
    expect(analytics.orders.byStatus.total, 10);
    expect(analytics.userGrowth.single.count, 7);
    expect(analytics.merchantGrowth.single.count, 2);
    expect(analytics.products.byCategory.single.category, 'Shoes');
    expect(analytics.products.byStatus.outOfStock, 2);
    expect(analytics.isEmpty, isFalse);
  });

  test('missing collections and values become an empty analytics state', () {
    final analytics = AdminAnalyticsModel.fromJson({});

    expect(analytics.isEmpty, isTrue);
    expect(analytics.sales.monthlySales, isEmpty);
    expect(analytics.orders.byStatus.total, 0);
  });
}
