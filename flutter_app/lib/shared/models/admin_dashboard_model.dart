class AdminDashboardModel {
  const AdminDashboardModel({
    required this.overview,
    required this.newestUsers,
    required this.newestStores,
    required this.newestProducts,
    required this.recentOrders,
  });

  final AdminSystemOverview overview;
  final List<AdminUserActivity> newestUsers;
  final List<AdminStoreActivity> newestStores;
  final List<AdminProductActivity> newestProducts;
  final List<AdminOrderActivity> recentOrders;

  bool get isEmpty =>
      overview.totalItems == 0 &&
      newestUsers.isEmpty &&
      newestStores.isEmpty &&
      newestProducts.isEmpty &&
      recentOrders.isEmpty;

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    final overviewJson = _map(json['system_overview']);
    final marketplace = _map(json['marketplace']);

    return AdminDashboardModel(
      overview: AdminSystemOverview.fromJson(overviewJson),
      newestUsers: _list(marketplace['newest_users'])
          .map(AdminUserActivity.fromJson)
          .toList(),
      newestStores: _list(marketplace['newest_stores'])
          .map(AdminStoreActivity.fromJson)
          .toList(),
      newestProducts: _list(marketplace['newest_products'])
          .map(AdminProductActivity.fromJson)
          .toList(),
      recentOrders: _list(marketplace['recent_orders'])
          .map(AdminOrderActivity.fromJson)
          .toList(),
    );
  }
}

class AdminSystemOverview {
  const AdminSystemOverview({
    required this.users,
    required this.stores,
    required this.products,
    required this.orders,
    required this.totalSales,
  });

  final AdminUserStats users;
  final AdminStoreStats stores;
  final AdminProductStats products;
  final AdminOrderStats orders;
  final double totalSales;

  int get totalItems =>
      users.total + stores.total + products.total + orders.total;

  factory AdminSystemOverview.fromJson(Map<String, dynamic> json) {
    return AdminSystemOverview(
      users: AdminUserStats.fromJson(_map(json['users'])),
      stores: AdminStoreStats.fromJson(_map(json['stores'])),
      products: AdminProductStats.fromJson(_map(json['products'])),
      orders: AdminOrderStats.fromJson(_map(json['orders'])),
      totalSales: _number(json['total_sales']),
    );
  }
}

class AdminUserStats {
  const AdminUserStats({
    required this.total,
    required this.clients,
    required this.merchants,
    required this.admins,
  });

  final int total;
  final int clients;
  final int merchants;
  final int admins;

  factory AdminUserStats.fromJson(Map<String, dynamic> json) {
    return AdminUserStats(
      total: _integer(json['total']),
      clients: _integer(json['clients']),
      merchants: _integer(json['merchants']),
      admins: _integer(json['admins']),
    );
  }
}

class AdminStoreStats {
  const AdminStoreStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.suspended,
  });

  final int total;
  final int active;
  final int inactive;
  final int suspended;

  factory AdminStoreStats.fromJson(Map<String, dynamic> json) {
    return AdminStoreStats(
      total: _integer(json['total']),
      active: _integer(json['active']),
      inactive: _integer(json['inactive']),
      suspended: _integer(json['suspended']),
    );
  }
}

class AdminProductStats {
  const AdminProductStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.outOfStock,
  });

  final int total;
  final int active;
  final int inactive;
  final int outOfStock;

  factory AdminProductStats.fromJson(Map<String, dynamic> json) {
    return AdminProductStats(
      total: _integer(json['total']),
      active: _integer(json['active']),
      inactive: _integer(json['inactive']),
      outOfStock: _integer(json['out_of_stock']),
    );
  }
}

class AdminOrderStats {
  const AdminOrderStats({
    required this.total,
    required this.pending,
    required this.confirmed,
    required this.processing,
    required this.completed,
    required this.cancelled,
  });

  final int total;
  final int pending;
  final int confirmed;
  final int processing;
  final int completed;
  final int cancelled;

  factory AdminOrderStats.fromJson(Map<String, dynamic> json) {
    return AdminOrderStats(
      total: _integer(json['total']),
      pending: _integer(json['pending']),
      confirmed: _integer(json['confirmed']),
      processing: _integer(json['processing']),
      completed: _integer(json['completed']),
      cancelled: _integer(json['cancelled']),
    );
  }
}

class AdminUserActivity {
  const AdminUserActivity({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  final String name;
  final String email;
  final String role;
  final String status;

  factory AdminUserActivity.fromJson(Map<String, dynamic> json) {
    return AdminUserActivity(
      name: _text(json['name'], fallback: 'مستخدم'),
      email: _text(json['email']),
      role: _text(json['role']),
      status: _text(json['status']),
    );
  }
}

class AdminStoreActivity {
  const AdminStoreActivity({
    required this.name,
    required this.status,
    required this.ownerName,
  });

  final String name;
  final String status;
  final String ownerName;

  factory AdminStoreActivity.fromJson(Map<String, dynamic> json) {
    final owner = _map(json['owner']);
    return AdminStoreActivity(
      name: _text(json['store_name'], fallback: 'متجر'),
      status: _text(json['status']),
      ownerName: _text(owner['name']),
    );
  }
}

class AdminProductActivity {
  const AdminProductActivity({
    required this.name,
    required this.status,
    required this.storeName,
    required this.categoryName,
  });

  final String name;
  final String status;
  final String storeName;
  final String categoryName;

  factory AdminProductActivity.fromJson(Map<String, dynamic> json) {
    final store = _map(json['store']);
    final category = _map(json['category']);
    return AdminProductActivity(
      name: _text(json['name'], fallback: 'منتج'),
      status: _text(json['status']),
      storeName: _text(store['store_name']),
      categoryName: _text(category['name']),
    );
  }
}

class AdminOrderActivity {
  const AdminOrderActivity({
    required this.id,
    required this.status,
    required this.customerName,
    required this.storeName,
    required this.amount,
  });

  final String id;
  final String status;
  final String customerName;
  final String storeName;
  final double amount;

  factory AdminOrderActivity.fromJson(Map<String, dynamic> json) {
    final client = _map(json['client']);
    final store = _map(json['store']);
    return AdminOrderActivity(
      id: _text(json['id'], fallback: '—'),
      status: _text(json['status']),
      customerName: _text(
        json['customer_name'] ?? client['name'],
        fallback: 'عميل',
      ),
      storeName: _text(store['store_name']),
      amount: _number(json['total_amount']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
}

int _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}
