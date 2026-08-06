// ─── AI Tool Types ────────────────────────────────────────────────────────────

enum AiToolType {
  productDescription,
  instagramPost,
  hashtags,
  customerReply,
}

extension AiToolTypeLabel on AiToolType {
  String get label {
    switch (this) {
      case AiToolType.productDescription:
        return 'وصف منتج';
      case AiToolType.instagramPost:
        return 'بوست انستغرام';
      case AiToolType.hashtags:
        return 'هاشتاقات';
      case AiToolType.customerReply:
        return 'رد عميل';
    }
  }
}

// ─── AI Status ────────────────────────────────────────────────────────────────

enum AiStatus { idle, loading, success, error }

// ─── AI Result ────────────────────────────────────────────────────────────────

class AiResult {
  /// Which tool produced this result.
  final AiToolType tool;

  /// The user-supplied prompt / inputs joined as a readable string.
  final String prompt;

  /// The generated output text.
  final String output;

  final DateTime generatedAt;

  const AiResult({
    required this.tool,
    required this.prompt,
    required this.output,
    required this.generatedAt,
  });

  // ── JSON serialisation ───────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'tool': _toolTypeToString(tool),
        'prompt': prompt,
        'output': output,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory AiResult.fromJson(Map<String, dynamic> json) => AiResult(
        tool: _toolTypeFromString(json['tool'] as String? ?? ''),
        prompt: json['prompt'] as String? ?? '',
        output: json['output'] as String? ?? '',
        generatedAt: json['generatedAt'] != null
            ? DateTime.parse(json['generatedAt'] as String)
            : DateTime.now(),
      );

  static String _toolTypeToString(AiToolType tool) {
    switch (tool) {
      case AiToolType.productDescription: return 'product_description';
      case AiToolType.instagramPost:      return 'instagram_post';
      case AiToolType.hashtags:           return 'hashtags';
      case AiToolType.customerReply:      return 'customer_reply';
    }
  }

  static AiToolType _toolTypeFromString(String value) {
    switch (value) {
      case 'product_description': return AiToolType.productDescription;
      case 'instagram_post':      return AiToolType.instagramPost;
      case 'hashtags':            return AiToolType.hashtags;
      case 'customer_reply':      return AiToolType.customerReply;
      default:                    return AiToolType.productDescription;
    }
  }
}
