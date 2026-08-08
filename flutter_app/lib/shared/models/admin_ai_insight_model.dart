class AdminAiInsight {
  const AdminAiInsight({
    required this.result,
    required this.periodDays,
    required this.type,
    required this.language,
    required this.tokensUsed,
  });

  final String result;
  final int periodDays;
  final String type;
  final String language;
  final int tokensUsed;

  factory AdminAiInsight.fromJson(Map<String, dynamic> json) {
    return AdminAiInsight(
      result: json['result']?.toString().trim() ?? '',
      periodDays: _integer(json['period_days'], fallback: 30),
      type: json['type']?.toString() ?? 'overview',
      language: json['language']?.toString() ?? 'English',
      tokensUsed: _integer(json['tokens_used']),
    );
  }
}

int _integer(Object? value, {int fallback = 0}) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
