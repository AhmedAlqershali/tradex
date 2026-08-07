class AdminCategory {
  const AdminCategory({
    required this.id,
    required this.name,
    required this.status,
    required this.productsCount,
    this.image,
    this.createdAt,
  });

  final String id;
  final String name;
  final String status;
  final int productsCount;
  final String? image;
  final DateTime? createdAt;

  bool get isActive => status == 'active';

  factory AdminCategory.fromJson(Map<String, dynamic> json) {
    return AdminCategory(
      id: _text(json['id']),
      name: _text(json['name']),
      image: _nullableText(json['image']),
      status: _text(json['status'], fallback: 'active'),
      productsCount: _integer(json['products_count']),
      createdAt: _date(json['created_at']),
    );
  }
}

class AdminCategoryPage {
  const AdminCategoryPage({
    required this.categories,
    required this.pagination,
  });

  final List<AdminCategory> categories;
  final AdminCategoryPagination pagination;

  bool get isEmpty => categories.isEmpty;
}

class AdminCategoryPagination {
  const AdminCategoryPagination({
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

  factory AdminCategoryPagination.fromJson(Map<String, dynamic> json) {
    return AdminCategoryPagination(
      total: _integer(json['total']),
      perPage: _integer(json['per_page'], fallback: 20),
      currentPage: _integer(json['current_page'], fallback: 1),
      lastPage: _integer(json['last_page'], fallback: 1),
    );
  }
}

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? null : text;
}

DateTime? _date(Object? value) {
  final text = _nullableText(value);
  return text == null ? null : DateTime.tryParse(text);
}

int _integer(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
