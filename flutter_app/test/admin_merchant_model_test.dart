import 'package:ai_saas/shared/models/admin_merchant_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses merchant owner and subscription lifecycle data', () {
    final merchant = AdminMerchant.fromJson({
      'id': 12,
      'store_name': 'Tradex Store',
      'description': 'Marketplace store',
      'status': 'active',
      'products_count': 4,
      'orders_count': 8,
      'owner': {
        'id': 9,
        'name': 'Mariam Merchant',
        'email': 'mariam@example.com',
        'phone': '0500001234',
        'role': 'merchant',
        'status': 'active',
        'current_subscription': {
          'id': 3,
          'plan': {'id': 1, 'display_name': 'Free Trial'},
          'billing_cycle': 'monthly',
          'type': 'trial',
          'is_trial': true,
          'status': 'active',
          'is_entitled': true,
          'starts_at': '2026-08-01T10:00:00Z',
          'ends_at': '2026-08-15T10:00:00Z',
        },
      },
    });

    expect(merchant.owner?.email, 'mariam@example.com');
    expect(merchant.productsCount, 4);
    expect(merchant.owner?.currentSubscription?.isTrial, isTrue);
    expect(merchant.owner?.currentSubscription?.isEntitled, isTrue);
    expect(merchant.owner?.currentSubscription?.endsAt, isNotNull);
  });

  test('defaults optional counts and missing subscription safely', () {
    final merchant = AdminMerchant.fromJson({
      'id': 13,
      'store_name': 'Store',
      'description': '',
      'status': 'suspended',
    });

    expect(merchant.productsCount, 0);
    expect(merchant.ordersCount, 0);
    expect(merchant.owner, isNull);
  });
}
