class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.avatar,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.stores = const [],
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String? avatar;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AdminUserStore> stores;

  String get displayName => name.trim().isEmpty ? 'مستخدم' : name.trim();

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: _text(json['id']),
      name: _text(json['name']),
      email: _text(json['email']),
      phone: _text(json['phone']),
      role: _text(json['role'], fallback: 'client'),
      status: _text(json['status'], fallback: 'active'),
      avatar: _nullableText(json['avatar']),
      emailVerifiedAt: _date(json['email_verified_at']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      stores: _list(json['stores']).map(AdminUserStore.fromJson).toList(),
    );
  }
}

class AdminUserStore {
  const AdminUserStore({
    required this.id,
    required this.name,
    required this.description,
    required this.logo,
    required this.status,
  });

  final String id;
  final String name;
  final String description;
  final String? logo;
  final String status;

  factory AdminUserStore.fromJson(Map<String, dynamic> json) {
    return AdminUserStore(
      id: _text(json['id']),
      name: _text(json['store_name']),
      description: _text(json['description']),
      logo: _nullableText(json['logo']),
      status: _text(json['status']),
    );
  }
}

class AdminUserPage {
  const AdminUserPage({
    required this.users,
    required this.pagination,
  });

  final List<AdminUser> users;
  final AdminUserPagination pagination;

  bool get isEmpty => users.isEmpty;
}

class AdminUserPagination {
  const AdminUserPagination({
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

  factory AdminUserPagination.fromJson(Map<String, dynamic> json) {
    return AdminUserPagination(
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

DateTime? _date(Object? value) {
  final text = _nullableText(value);
  return text == null ? null : DateTime.tryParse(text);
}

int _integer(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
}
