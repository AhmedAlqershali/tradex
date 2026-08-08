class AdminSubscriptionRequest {
  const AdminSubscriptionRequest({
    required this.id,
    required this.merchant,
    required this.plan,
    required this.billingCycle,
    required this.fullName,
    required this.phone,
    required this.paymentMethod,
    required this.paymentProofUrl,
    required this.notes,
    required this.status,
    required this.rejectionReason,
    required this.reviewer,
    required this.reviewedAt,
    required this.createdAt,
  });

  final String id;
  final AdminSubscriptionUser? merchant;
  final AdminSubscriptionPlan? plan;
  final String billingCycle;
  final String fullName;
  final String phone;
  final String paymentMethod;
  final String? paymentProofUrl;
  final String? notes;
  final String status;
  final String? rejectionReason;
  final AdminSubscriptionUser? reviewer;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';

  factory AdminSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return AdminSubscriptionRequest(
      id: _text(json['id']),
      merchant: _nested(json['merchant'], AdminSubscriptionUser.fromJson),
      plan: _nested(json['plan'], AdminSubscriptionPlan.fromJson),
      billingCycle: _text(json['billing_cycle']),
      fullName: _text(json['full_name']),
      phone: _text(json['phone']),
      paymentMethod: _text(json['payment_method']),
      paymentProofUrl: _nullableText(json['payment_proof_url']),
      notes: _nullableText(json['notes']),
      status: _text(json['status'], fallback: 'pending'),
      rejectionReason: _nullableText(json['rejection_reason']),
      reviewer: _nested(json['reviewed_by'], AdminSubscriptionUser.fromJson),
      reviewedAt: _date(json['reviewed_at']),
      createdAt: _date(json['created_at']),
    );
  }
}

class AdminSubscriptionUser {
  const AdminSubscriptionUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? role;

  factory AdminSubscriptionUser.fromJson(Map<String, dynamic> json) {
    return AdminSubscriptionUser(
      id: _text(json['id']),
      name: _text(json['name'], fallback: 'غير معروف'),
      email: _nullableText(json['email']),
      phone: _nullableText(json['phone']),
      role: _nullableText(json['role']),
    );
  }
}

class AdminSubscriptionPlan {
  const AdminSubscriptionPlan({
    required this.id,
    required this.displayName,
    required this.monthlyPrice,
    required this.yearlyPrice,
  });

  final String id;
  final String displayName;
  final double monthlyPrice;
  final double yearlyPrice;

  factory AdminSubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return AdminSubscriptionPlan(
      id: _text(json['id']),
      displayName: _text(json['display_name'], fallback: _text(json['name'])),
      monthlyPrice: _decimal(json['monthly_price']),
      yearlyPrice: _decimal(json['yearly_price']),
    );
  }
}

class AdminSubscriptionRequestPage {
  const AdminSubscriptionRequestPage({
    required this.requests,
    required this.pagination,
  });

  final List<AdminSubscriptionRequest> requests;
  final AdminSubscriptionRequestPagination pagination;

  bool get isEmpty => requests.isEmpty;
}

class AdminSubscriptionRequestPagination {
  const AdminSubscriptionRequestPagination({
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

  factory AdminSubscriptionRequestPagination.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminSubscriptionRequestPagination(
      total: _integer(json['total']),
      perPage: _integer(json['per_page'], fallback: 15),
      currentPage: _integer(json['current_page'], fallback: 1),
      lastPage: _integer(json['last_page'], fallback: 1),
    );
  }
}

T? _nested<T>(
  Object? value,
  T Function(Map<String, dynamic>) fromJson,
) {
  return value is Map ? fromJson(Map<String, dynamic>.from(value)) : null;
}

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? null : text;
}

double _decimal(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int _integer(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

DateTime? _date(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? null : DateTime.tryParse(text);
}