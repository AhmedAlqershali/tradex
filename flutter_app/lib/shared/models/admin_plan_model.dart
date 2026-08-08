class AdminPlan {
  const AdminPlan({
    required this.id,
    required this.name,
    required this.displayName,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.aiUsageLimit,
    required this.productLimit,
    required this.storeLimit,
    required this.features,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String name;
  final String displayName;
  final double monthlyPrice;
  final double yearlyPrice;
  final int? aiUsageLimit;
  final int? productLimit;
  final int storeLimit;
  final List<String> features;
  final String status;
  final DateTime? createdAt;

  bool get isActive => status == 'active';

  factory AdminPlan.fromJson(Map<String, dynamic> json) {
    return AdminPlan(
      id: _text(json['id']),
      name: _text(json['name']),
      displayName: _text(json['display_name']),
      monthlyPrice: _decimal(json['monthly_price']),
      yearlyPrice: _decimal(json['yearly_price']),
      aiUsageLimit: _nullableInteger(json['ai_usage_limit']),
      productLimit: _nullableInteger(json['product_limit']),
      storeLimit: _integer(json['store_limit'], fallback: 1),
      features: _features(json['features']),
      status: _text(json['status'], fallback: 'active'),
      createdAt: _date(json['created_at']),
    );
  }
}

class AdminPlanPage {
  const AdminPlanPage({
    required this.plans,
    required this.pagination,
  });

  final List<AdminPlan> plans;
  final AdminPlanPagination pagination;

  bool get isEmpty => plans.isEmpty;
}

class AdminPlanPagination {
  const AdminPlanPagination({
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

  factory AdminPlanPagination.fromJson(Map<String, dynamic> json) {
    return AdminPlanPagination(
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

double _decimal(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int _integer(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

int? _nullableInteger(Object? value) {
  if (value == null) return null;
  return _integer(value);
}

List<String> _features(Object? value) {
  if (value is List) {
    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is Map) {
    return value.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}

DateTime? _date(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? null : DateTime.tryParse(text);
}
