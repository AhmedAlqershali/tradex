class AdminAnalyticsModel {
  const AdminAnalyticsModel({
    required this.sales,
    required this.orders,
    required this.userGrowth,
    required this.merchantGrowth,
    required this.products,
  });

  final AdminSalesStatistics sales;
  final AdminOrderStatistics orders;
  final List<AdminGrowthPoint> userGrowth;
  final List<AdminGrowthPoint> merchantGrowth;
  final AdminProductStatistics products;

  bool get isEmpty =>
      sales.monthlySales.isEmpty &&
      orders.byStatus.total == 0 &&
      userGrowth.isEmpty &&
      merchantGrowth.isEmpty &&
      products.byCategory.isEmpty &&
      products.byStatus.total == 0;

  factory AdminAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsModel(
      sales: AdminSalesStatistics.fromJson(_map(json['sales_statistics'])),
      orders: AdminOrderStatistics.fromJson(_map(json['order_statistics'])),
      userGrowth:
          _list(json['user_growth']).map(AdminGrowthPoint.fromJson).toList(),
      merchantGrowth: _list(json['merchant_growth'])
          .map(AdminGrowthPoint.fromJson)
          .toList(),
      products: AdminProductStatistics.fromJson(
        _map(json['product_statistics']),
      ),
    );
  }
}

class AdminSalesStatistics {
  const AdminSalesStatistics({required this.monthlySales});

  final List<AdminMonthlySale> monthlySales;

  factory AdminSalesStatistics.fromJson(Map<String, dynamic> json) {
    return AdminSalesStatistics(
      monthlySales:
          _list(json['monthly_sales']).map(AdminMonthlySale.fromJson).toList(),
    );
  }
}

class AdminMonthlySale {
  const AdminMonthlySale({
    required this.year,
    required this.month,
    required this.revenue,
    required this.orderCount,
  });

  final int year;
  final int month;
  final double revenue;
  final int orderCount;

  String get label => '$month/$year';

  factory AdminMonthlySale.fromJson(Map<String, dynamic> json) {
    return AdminMonthlySale(
      year: _integer(json['year']),
      month: _integer(json['month']),
      revenue: _number(json['revenue']),
      orderCount: _integer(json['order_count']),
    );
  }
}

class AdminOrderStatistics {
  const AdminOrderStatistics({required this.byStatus});

  final AdminOrderStatusCounts byStatus;

  factory AdminOrderStatistics.fromJson(Map<String, dynamic> json) {
    return AdminOrderStatistics(
      byStatus: AdminOrderStatusCounts.fromJson(_map(json['by_status'])),
    );
  }
}

class AdminOrderStatusCounts {
  const AdminOrderStatusCounts({
    required this.pendingReview,
    required this.confirmed,
    required this.completed,
    required this.cancelled,
  });

  final int pendingReview;
  final int confirmed;
  final int completed;
  final int cancelled;

  int get total => pendingReview + confirmed + completed + cancelled;

  factory AdminOrderStatusCounts.fromJson(Map<String, dynamic> json) {
    return AdminOrderStatusCounts(
      pendingReview: _integer(json['pending_review']),
      confirmed: _integer(json['confirmed']),
      completed: _integer(json['completed']),
      cancelled: _integer(json['cancelled']),
    );
  }
}

class AdminGrowthPoint {
  const AdminGrowthPoint({
    required this.year,
    required this.month,
    required this.count,
  });

  final int year;
  final int month;
  final int count;

  String get label => '$month/$year';

  factory AdminGrowthPoint.fromJson(Map<String, dynamic> json) {
    return AdminGrowthPoint(
      year: _integer(json['year']),
      month: _integer(json['month']),
      count: _integer(json['new_users'] ?? json['new_merchants']),
    );
  }
}

class AdminProductStatistics {
  const AdminProductStatistics({
    required this.byCategory,
    required this.byStatus,
  });

  final List<AdminCategoryProductCount> byCategory;
  final AdminProductStatusCounts byStatus;

  factory AdminProductStatistics.fromJson(Map<String, dynamic> json) {
    return AdminProductStatistics(
      byCategory: _list(json['by_category'])
          .map(AdminCategoryProductCount.fromJson)
          .toList(),
      byStatus: AdminProductStatusCounts.fromJson(_map(json['by_status'])),
    );
  }
}

class AdminCategoryProductCount {
  const AdminCategoryProductCount({
    required this.category,
    required this.count,
  });

  final String category;
  final int count;

  factory AdminCategoryProductCount.fromJson(Map<String, dynamic> json) {
    return AdminCategoryProductCount(
      category: json['category']?.toString() ?? '',
      count: _integer(json['count']),
    );
  }
}

class AdminProductStatusCounts {
  const AdminProductStatusCounts({
    required this.active,
    required this.inactive,
    required this.outOfStock,
  });

  final int active;
  final int inactive;
  final int outOfStock;

  int get total => active + inactive + outOfStock;

  factory AdminProductStatusCounts.fromJson(Map<String, dynamic> json) {
    return AdminProductStatusCounts(
      active: _integer(json['active']),
      inactive: _integer(json['inactive']),
      outOfStock: _integer(json['out_of_stock']),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value.whereType<Map>().map(_map).toList();
}

int _integer(dynamic value) => value is num
    ? value.toInt()
    : int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;

double _number(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
