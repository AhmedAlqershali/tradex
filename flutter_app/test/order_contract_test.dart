import 'package:flutter_test/flutter_test.dart';

import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/presentation/blocs/order/order_bloc.dart';
import 'package:ai_saas/shared/models/mock_order.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';

void main() {
  test('merchant list order id is carried unchanged into detail path', () {
    final order = AppOrder.fromServerJson({
      'id': 42,
      'status': 'pending',
      'created_at': '2026-08-14T10:00:00Z',
      'customer_name': 'Customer',
      'customer_phone': '000',
      'customer_city': 'City',
      'store': {'id': 7, 'store_name': 'Store'},
      'items': [
        {
          'id': 1,
          'product_id': 9,
          'product_name': 'Product',
          'unit_price': 12.5,
          'quantity': 2,
          'subtotal': 25,
        },
      ],
    });

    expect(order.ref, '42');
    expect(ApiConstants.merchantOrderById(order.ref), '/merchant/orders/42');
  });

  test('all backend lifecycle statuses parse to distinct UI statuses', () {
    final statuses = {
      'pending': OrderStatus.pendingReview,
      'contacted': OrderStatus.merchantContacted,
      'confirmed': OrderStatus.orderConfirmed,
      'processing': OrderStatus.preparing,
      'completed': OrderStatus.completed,
      'cancelled': OrderStatus.cancelled,
    };

    for (final entry in statuses.entries) {
      final order = AppOrder.fromServerJson({
        'id': 42,
        'status': entry.key,
        'created_at': '2026-08-14T10:00:00Z',
        'customer_name': 'Customer',
        'customer_phone': '0591234567',
        'customer_city': 'City',
      });
      expect(order.status, entry.value);
      expect(OrderController.parseStatus(entry.key), entry.value);
    }
  });

  test('order failures retain typed errors for detail UI classification', () {
    const notFound = ServerException('Order not found.', statusCode: 404);
    const forbidden = ForbiddenException('Forbidden.');
    const unauthenticated = AuthException('Unauthenticated.');
    const server = ServerException('Server failure.', statusCode: 500);
    const network = NetworkException('Network failure.');

    expect(
      OrderFailure(notFound.message, error: notFound).error,
      same(notFound),
    );
    expect(
      OrderFailure(forbidden.message, error: forbidden).error,
      same(forbidden),
    );
    expect(
      OrderFailure(unauthenticated.message, error: unauthenticated).error,
      same(unauthenticated),
    );
    expect(OrderFailure(server.message, error: server).error, same(server));
    expect(OrderFailure(network.message, error: network).error, same(network));
  });
}
