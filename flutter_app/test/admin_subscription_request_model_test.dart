import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/shared/models/admin_subscription_request_model.dart';

void main() {
  test('parses a Laravel subscription request resource', () {
    final request = AdminSubscriptionRequest.fromJson({
      'id': 7,
      'merchant': {
        'id': 3,
        'name': 'Merchant',
        'email': 'merchant@example.com',
        'phone': '0501234567',
        'role': 'merchant',
      },
      'plan': {
        'id': 2,
        'name': 'pro',
        'display_name': 'Pro',
        'monthly_price': '49.99',
        'yearly_price': 499.99,
      },
      'billing_cycle': 'monthly',
      'full_name': 'Merchant',
      'phone': '0501234567',
      'payment_method': 'bank_transfer',
      'payment_proof_url': '/proof',
      'notes': 'Please review',
      'status': 'pending',
      'created_at': '2026-08-08T10:00:00Z',
    });

    expect(request.id, '7');
    expect(request.merchant?.email, 'merchant@example.com');
    expect(request.plan?.displayName, 'Pro');
    expect(request.plan?.monthlyPrice, 49.99);
    expect(request.isPending, isTrue);
  });

  test('parses request pagination', () {
    final pagination = AdminSubscriptionRequestPagination.fromJson({
      'total': 16,
      'per_page': 15,
      'current_page': 2,
      'last_page': 2,
    });

    expect(pagination.hasPrevious, isTrue);
    expect(pagination.hasNext, isFalse);
  });
}