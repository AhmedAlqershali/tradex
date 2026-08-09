class MerchantDashboardModel {
  const MerchantDashboardModel({
    required this.products,
    required this.orders,
    required this.totalSales,
    required this.recentOrders,
    required this.topProducts,
    required this.lowInventory,
  });

  final MerchantProductStats products;
  final MerchantOrderStats orders;
  final double totalSales;
  final List<MerchantDashboardOrder> recentOrders;
  final List<MerchantDashboardProduct> topProducts;
  final List<MerchantDashboardProduct> lowInventory;

  bool get isEmpty =>
      products.total == 0 &&
      orders.total == 0 &&
      totalSales == 0 &&
      recentOrders.isEmpty &&
      topProducts.isEmpty &&
      lowInventory.isEmpty;

  factory MerchantDashboardModel.fromJson(Map<String, dynamic> json) {
    return MerchantDashboardModel(
      products: MerchantProductStats.fromJson(_map(json['products'])),
      orders: MerchantOrderStats.fromJson(_map(json['orders'])),
      totalSales: _number(json['total_sales']),
      recentOrders: _list(json['recent_orders'])
          .map(MerchantDashboardOrder.fromJson)
          .toList(),
      topProducts: _list(json['top_products'])
          .map(MerchantDashboardProduct.fromJson)
          .toList(),
      lowInventory: _list(json['low_inventory'])
          .map(MerchantDashboardProduct.fromJson)
          .toList(),
    );
  }
}

class MerchantProductStats {
  const MerchantProductStats({
    required this.total,
    required this.active,
    required this.outOfStock,
    required this.lowStock,
  });

  final int total;
  final int active;
  final int outOfStock;
  final int lowStock;

  factory MerchantProductStats.fromJson(Map<String, dynamic> json) {
    return MerchantProductStats(
      total: _integer(json['total']),
      active: _integer(json['active']),
      outOfStock: _integer(json['out_of_stock']),
      lowStock: _integer(json['low_stock']),
    );
  }
}

class MerchantOrderStats {
  const MerchantOrderStats({
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

  factory MerchantOrderStats.fromJson(Map<String, dynamic> json) {
    return MerchantOrderStats(
      total: _integer(json['total']),
      pending: _integer(json['pending']),
      confirmed: _integer(json['confirmed']),
      processing: _integer(json['processing']),
      completed: _integer(json['completed']),
      cancelled: _integer(json['cancelled']),
    );
  }
}

class MerchantDashboardOrder {
  const MerchantDashboardOrder({
    required this.id,
    required this.status,
    required this.customerName,
    required this.totalAmount,
  });

  final String id;
  final String status;
  final String customerName;
  final double totalAmount;

  factory MerchantDashboardOrder.fromJson(Map<String, dynamic> json) {
    return MerchantDashboardOrder(
      id: _text(json['id'], fallback: '—'),
      status: _text(json['status']),
      customerName: _text(json['customer_name'], fallback: 'عميل'),
      totalAmount: _number(json['total_amount']),
    );
  }
}

class MerchantDashboardProduct {
  const MerchantDashboardProduct({
    required this.id,
    required this.name,
    required this.quantity,
    required this.status,
    required this.price,
  });

  final String id;
  final String name;
  final int quantity;
  final String status;
  final double price;

  factory MerchantDashboardProduct.fromJson(Map<String, dynamic> json) {
    return MerchantDashboardProduct(
      id: _text(json['id'], fallback: '—'),
      name: _text(json['name'], fallback: 'منتج'),
      quantity: _integer(json['quantity']),
      status: _text(json['status']),
      price: _number(json['price']),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

int _integer(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _text(dynamic value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}