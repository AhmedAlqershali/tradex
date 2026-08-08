import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/shared/models/admin_plan_model.dart';

void main() {
  test('parses the Laravel plan resource and pagination', () {
    final plan = AdminPlan.fromJson({
      'id': 3,
      'name': 'pro',
      'display_name': 'Pro Plan',
      'monthly_price': '49.99',
      'yearly_price': 499.99,
      'ai_usage_limit': null,
      'product_limit': 100,
      'store_limit': 3,
      'features': ['priority_support'],
      'status': 'inactive',
      'created_at': '2026-08-08T10:00:00Z',
    });

    expect(plan.id, '3');
    expect(plan.monthlyPrice, 49.99);
    expect(plan.aiUsageLimit, isNull);
    expect(plan.features, ['priority_support']);
    expect(plan.isActive, isFalse);
  });

  test('parses pagination metadata returned by the collection', () {
    final pagination = AdminPlanPagination.fromJson({
      'total': 25,
      'per_page': 20,
      'current_page': 2,
      'last_page': 2,
    });

    expect(pagination.total, 25);
    expect(pagination.hasPrevious, isTrue);
    expect(pagination.hasNext, isFalse);
  });
}
