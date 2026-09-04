import 'package:ai_saas/shared/models/search_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses product and store results from the API envelope', () {
    final result = UnifiedSearchResult.fromServerJson({
      'data': {
        'products': {
          'data': [
            {
              'id': 1,
              'name': 'iPhone 17',
              'store_id': 2,
              'store_name': 'Apple Store',
              'price': 100,
              'quantity': 2,
              'status': 'active',
              'images': [],
              'created_at': '2026-01-01T00:00:00Z',
            },
          ],
        },
        'stores': {
          'data': [
            {
              'id': 2,
              'store_name': 'Apple Store',
              'description': 'Mobile devices',
            },
          ],
        },
      },
    });

    expect(result.products, hasLength(1));
    expect(result.products.single.name, 'iPhone 17');
    expect(result.stores, hasLength(1));
    expect(result.stores.single.id, '2');
    expect(result.stores.single.title, 'Apple Store');
  });
}