import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/shared/models/product_model.dart';

void main() {
  test('parses the Laravel product contract', () {
    final product = Product.fromServerJson({
      'id': 42,
      'store_id': 7,
      'category_id': 3,
      'category': {'id': 3, 'name': 'Shoes'},
      'name': 'Canvas shoes',
      'description': 'Lightweight shoes',
      'price': '19.50',
      'quantity': '4',
      'status': 'active',
      'is_available': true,
      'images': [
        {'id': 1, 'url': 'https://example.test/one.jpg'},
        {'id': 2, 'url': 'https://example.test/two.jpg'},
      ],
      'store': {'id': 7, 'store_name': 'Demo Store'},
      'created_at': '2026-08-11T12:00:00Z',
    });

    expect(product.id, '42');
    expect(product.storeId, '7');
    expect(product.categoryId, '3');
    expect(product.category, 'Shoes');
    expect(product.name, 'Canvas shoes');
    expect(product.description, 'Lightweight shoes');
    expect(product.price, 19.5);
    expect(product.quantity, 4);
    expect(product.isAvailable, isTrue);
    expect(product.imageUrls, [
      'https://example.test/one.jpg',
      'https://example.test/two.jpg',
    ]);
    expect(product.storeName, 'Demo Store');
  });

  test('does not make zero-stock or inactive products available', () {
    final outOfStock = Product.fromServerJson({
      'id': 1,
      'name': 'Sold out',
      'price': 10,
      'quantity': 0,
      'status': 'active',
    });
    final inactive = Product.fromServerJson({
      'id': 2,
      'name': 'Hidden',
      'price': 10,
      'quantity': 5,
      'status': 'inactive',
    });

    expect(outOfStock.isAvailable, isFalse);
    expect(inactive.isAvailable, isFalse);
    expect(outOfStock.imageUrls, isEmpty);
  });
}
