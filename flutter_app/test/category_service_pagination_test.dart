import 'package:ai_saas/core/services/category_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merges category data from all paginated responses', () {
    final firstPage = {
      'data': [
        {'id': 1, 'name': 'Electronics'},
        {'id': 2, 'name': 'Fashion'},
      ],
      'pagination': {
        'total': 3,
        'per_page': 2,
        'current_page': 1,
        'last_page': 2,
      },
    };

    final secondPage = {
      'data': [
        {'id': 3, 'name': 'Books'},
      ],
      'pagination': {
        'total': 3,
        'per_page': 2,
        'current_page': 2,
        'last_page': 2,
      },
    };

    final merged = CategoryService.mergePaginatedResponses([firstPage, secondPage]);

    expect(merged.map((option) => option.name).toList(), ['Electronics', 'Fashion', 'Books']);
  });
}
