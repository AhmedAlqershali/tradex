import 'package:ai_saas/shared/models/admin_subscription_model.dart';

class AdminMerchant {
  const AdminMerchant({
    required this.id,
    required this.storeName,
    required this.description,
    required this.status,
    required this.productsCount,
    required this.ordersCount,
    this.logo,
    this.owner,
    this.products = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String storeName;
  final String description;
  final String status;
  final int productsCount;
  final int ordersCount;
  final String? logo;
  final AdminMerchantOwner? owner;
  final List<AdminMerchantProduct> products;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName =>
      storeName.trim().isEmpty ? 'متجر بدون اسم' : storeName.trim();

  factory AdminMerchant.fromJson(Map<String, dynamic> json) {
    return AdminMerchant(
      id: _text(json['id']),
      storeName: _text(json['store_name']),
      description: _text(json['description']),
      logo: _nullableText(json['logo']),
      status: _text(json['status'], fallback: 'inactive'),
      productsCount: _integer(json['products_count']),
      ordersCount: _integer(json['orders_count']),
      owner: _map(json['owner']) == null
          ? null
          : AdminMerchantOwner.fromJson(_map(json['owner'])!),
      products:
          _list(json['products']).map(AdminMerchantProduct.fromJson).toList(),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }
}

class AdminMerchantOwner {
  const AdminMerchantOwner({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.currentSubscription,
    this.subscriptionHistory = const [],
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final AdminSubscription? currentSubscription;
  final List<AdminSubscription> subscriptionHistory;

  String get displayName => name.trim().isEmpty ? 'تاجر' : name.trim();

  factory AdminMerchantOwner.fromJson(Map<String, dynamic> json) {
    return AdminMerchantOwner(
      id: _text(json['id']),
      name: _text(json['name']),
      email: _text(json['email']),
      phone: _text(json['phone']),
      role: _text(json['role'], fallback: 'merchant'),
      status: _text(json['status'], fallback: 'active'),
      currentSubscription: _nested(
        json['current_subscription'],
        AdminSubscription.fromJson,
      ),
      subscriptionHistory: _list(json['subscription_history'])
          .map(AdminSubscription.fromJson)
          .toList(),
    );
  }
}

T? _nested<T>(
  Object? value,
  T Function(Map<String, dynamic>) parse,
) {
  return value is Map ? parse(Map<String, dynamic>.from(value)) : null;
}

class AdminMerchantProduct {
  const AdminMerchantProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.status,
    this.image,
  });

  final String id;
  final String name;
  final double price;
  final String status;
  final String? image;

  factory AdminMerchantProduct.fromJson(Map<String, dynamic> json) {
    return AdminMerchantProduct(
      id: _text(json['id']),
      name: _text(json['name']),
      price: _number(json['price']),
      status: _text(json['status']),
      image: _nullableText(json['image']),
    );
  }
}

class AdminMerchantPage {
  const AdminMerchantPage({
    required this.merchants,
    required this.pagination,
  });

  final List<AdminMerchant> merchants;
  final AdminMerchantPagination pagination;

  bool get isEmpty => merchants.isEmpty;
}

class AdminMerchantPagination {
  const AdminMerchantPagination({
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

  factory AdminMerchantPagination.fromJson(Map<String, dynamic> json) {
    return AdminMerchantPagination(
      total: _integer(json['total']),
      perPage: _integer(json['per_page'], fallback: 15),
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

int _integer(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

double _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

DateTime? _date(Object? value) {
  final text = _nullableText(value);
  return text == null ? null : DateTime.tryParse(text);
}

Map<String, dynamic>? _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
}
