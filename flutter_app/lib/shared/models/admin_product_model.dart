import 'package:ai_saas/shared/models/product_model.dart';

class AdminProductPage {
  const AdminProductPage({
    required this.products,
    required this.pagination,
  });

  final List<Product> products;
  final AdminProductPagination pagination;

  bool get isEmpty => products.isEmpty;
}

class AdminProductPagination {
  const AdminProductPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  factory AdminProductPagination.fromJson(Map<String, dynamic> json) {
    return AdminProductPagination(
      total: _integer(json['total']),
      perPage: _integer(json['per_page'], fallback: 15),
      currentPage: _integer(json['current_page'], fallback: 1),
      lastPage: _integer(json['last_page'], fallback: 1),
    );
  }
}

int _integer(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
