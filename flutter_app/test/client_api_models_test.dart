import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/shared/cart/cart_controller.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';

void main() {
  test('CartItem parses the Laravel nested cart resource', () {
    final item = CartItem.fromServerJson({
      'id': 42,
      'quantity': 2,
      'unit_price': 19.5,
      'product': {
        'id': 7,
        'name': 'Canvas shoes',
        'image': 'https://example.test/shoes.jpg',
        'store': {'store_name': 'Demo Store'},
      },
    });

    expect(item.serverItemId, '42');
    expect(item.id, '7');
    expect(item.name, 'Canvas shoes');
    expect(item.storeName, 'Demo Store');
    expect(item.price, 19.5);
    expect(item.imageUrl, 'https://example.test/shoes.jpg');
    expect(item.lineTotal, 39);
  });

  test('AppOrder parses Laravel order items and store resource', () {
    final order = AppOrder.fromServerJson({
      'id': 101,
      'status': 'pending_review',
      'customer_name': 'Client',
      'customer_phone': '0500000000',
      'customer_city': 'Gaza',
      'store': {'store_name': 'Demo Store'},
      'items': [
        {
          'product_id': 7,
          'product_name': 'Canvas shoes',
          'unit_price': 25.0,
          'quantity': 2,
        },
      ],
    });

    expect(order.ref, '101');
    expect(order.storeName, 'Demo Store');
    expect(order.products.single.price, 25);
    expect(order.products.single.lineTotal, 50);
  });
}
