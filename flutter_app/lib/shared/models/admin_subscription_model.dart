class AdminSubscription {
  const AdminSubscription({
    required this.id,
    required this.planName,
    required this.billingCycle,
    required this.type,
    required this.isTrial,
    required this.status,
    required this.isEntitled,
    this.startsAt,
    this.endsAt,
    this.cancelledAt,
  });

  final String id;
  final String planName;
  final String billingCycle;
  final String type;
  final bool isTrial;
  final String status;
  final bool isEntitled;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? cancelledAt;

  factory AdminSubscription.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'];
    final planMap = plan is Map ? Map<String, dynamic>.from(plan) : const {};
    return AdminSubscription(
      id: _text(json['id']),
      planName: _text(
        planMap['display_name'] ?? planMap['name'],
        fallback: 'بدون خطة',
      ),
      billingCycle: _text(json['billing_cycle']),
      type: _text(json['type']),
      isTrial: json['is_trial'] == true,
      status: _text(json['status']),
      isEntitled: json['is_entitled'] == true,
      startsAt: _date(json['starts_at']),
      endsAt: _date(json['ends_at']),
      cancelledAt: _date(json['cancelled_at']),
    );
  }
}

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

DateTime? _date(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? null : DateTime.tryParse(text);
}
