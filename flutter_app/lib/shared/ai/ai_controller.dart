import 'package:flutter/material.dart';
import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'ai_result_model.dart';

// ─── AI Controller ────────────────────────────────────────────────────────────
//
// Singleton controller for all AI generation features. Calls the real
// backend AI endpoints:
//   POST /ai/product-description  { context, language }
//   POST /ai/marketing-content    { context, language }  — covers both the
//                                    Instagram-post and hashtags tools; the
//                                    backend returns one formatted block
//                                    ("Caption: ...\nHashtags: ...\n
//                                    Tagline: ..."), parsed client-side.
//   POST /ai/customer-reply       { context, language, store_name }
//
// There is no backend endpoint for the hashtags tool on its own — it shares
// /ai/marketing-content with the Instagram-post tool. Requesting both
// consecutively calls the backend twice (each generation is
// non-deterministic anyway, so the two calls needn't return matching
// hashtags/caption pairs).
// ─────────────────────────────────────────────────────────────────────────────

class AiController {
  AiController._();
  static final AiController instance = AiController._();

  // ── Public notifiers ─────────────────────────────────────────────────────────

  /// Current loading / result status.
  final ValueNotifier<AiStatus> statusNotifier =
      ValueNotifier(AiStatus.idle);

  /// The most recently generated result (null when idle).
  final ValueNotifier<AiResult?> resultNotifier = ValueNotifier(null);

  /// Running history of all generated results (newest first, max 20).
  final ValueNotifier<List<AiResult>> historyNotifier =
      ValueNotifier(const []);

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Generates a product description from the merchant's inputs.
  /// [name] — product name (required).
  /// [category] — product category (optional).
  /// [extra] — additional notes provided by the merchant (optional).
  Future<AiResult> generateProductDescription({
    required String name,
    String category = '',
    String extra = '',
  }) {
    final context = [
      name,
      if (category.isNotEmpty) 'الفئة: $category',
      if (extra.isNotEmpty) extra,
    ].join(' — ');
    return _generate(
      tool: AiToolType.productDescription,
      prompt: context,
      request: () => _post(ApiConstants.aiProductDescription, context),
    );
  }

  /// Generates an Instagram post caption for the given product.
  Future<AiResult> generateInstagramPost({
    required String productName,
    String category = '',
  }) {
    final context = [
      productName,
      if (category.isNotEmpty) 'الفئة: $category',
    ].join(' — ');
    return _generate(
      tool: AiToolType.instagramPost,
      prompt: context,
      request: () async =>
          _extractCaption(await _post(ApiConstants.aiMarketingContent, context)),
    );
  }

  /// Generates a list of relevant hashtags for the given topic.
  Future<AiResult> generateHashtags({
    required String topic,
    String category = '',
  }) {
    final context = [
      topic,
      if (category.isNotEmpty) 'الفئة: $category',
    ].join(' — ');
    return _generate(
      tool: AiToolType.hashtags,
      prompt: context,
      request: () async =>
          _extractHashtags(await _post(ApiConstants.aiMarketingContent, context)),
    );
  }

  /// Generates a professional reply to a customer's message.
  Future<AiResult> generateCustomerReply({
    required String customerMessage,
  }) {
    return _generate(
      tool: AiToolType.customerReply,
      prompt: customerMessage,
      request: () => _post(
        ApiConstants.aiCustomerReply,
        customerMessage,
      ),
    );
  }

  /// Resets the controller to idle state, clearing the current result.
  void clearResult() {
    statusNotifier.value = AiStatus.idle;
    resultNotifier.value = null;
  }

  // ── Generation engine ─────────────────────────────────────────────────────────

  Future<AiResult> _generate({
    required AiToolType tool,
    required String prompt,
    required Future<String> Function() request,
  }) async {
    statusNotifier.value = AiStatus.loading;
    resultNotifier.value = null;

    try {
      final output = await request();
      final result = AiResult(
        tool: tool,
        prompt: prompt,
        output: output,
        generatedAt: DateTime.now(),
      );

      resultNotifier.value = result;
      historyNotifier.value =
          [result, ...historyNotifier.value].take(20).toList();
      statusNotifier.value = AiStatus.success;
      return result;
    } on ApiException {
      statusNotifier.value = AiStatus.error;
      rethrow;
    } catch (e) {
      // Catch-all: ensures statusNotifier always reaches a terminal state even
      // for non-API errors (network timeout, type cast failures, etc.).
      // Without this, the AI tool sheet spinner hangs indefinitely.
      statusNotifier.value = AiStatus.error;
      rethrow;
    }
  }

  // ── Backend calls ─────────────────────────────────────────────────────────────

  /// POST to an /ai/* endpoint with the standard {context, language} body
  /// and returns the raw `result` text.
  /// The backend requires `context` to be at least 5 characters — very short
  /// merchant input is padded so the request doesn't fail validation for a
  /// reason the user can't see.
  Future<String> _post(String path, String context) async {
    final trimmed = context.trim();
    final safeContext = trimmed.length >= 5 ? trimmed : '$trimmed منتج مميز';
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      path,
      data: {
        'context': safeContext,
        'language': 'Arabic',
      },
    );
    final raw = response.data!;
    final body =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return body['result'] as String? ?? '';
  }

  // ── Marketing-content parsing ─────────────────────────────────────────────────
  //
  // The backend returns one block formatted as:
  //   Caption: <caption text>
  //   Hashtags: <hashtag1> <hashtag2> ...
  //   Tagline: <tagline text>
  // Parsed defensively — if the model doesn't follow the format exactly, the
  // whole block is returned rather than an empty string.

  String _extractCaption(String raw) {
    final caption = _extractLabelled(raw, 'Caption');
    final tagline = _extractLabelled(raw, 'Tagline');
    if (caption == null && tagline == null) return raw;
    return [caption, tagline]
        .where((s) => s != null && s.isNotEmpty)
        .join('\n\n');
  }

  String _extractHashtags(String raw) {
    final hashtags = _extractLabelled(raw, 'Hashtags');
    if (hashtags != null && hashtags.isNotEmpty) return hashtags;
    // Fallback: pull any #word tokens out of the raw text.
    final matches = RegExp(r'#\S+').allMatches(raw).map((m) => m.group(0)!);
    return matches.isNotEmpty ? matches.join(' ') : raw;
  }

  String? _extractLabelled(String raw, String label) {
    final match = RegExp('$label:\\s*(.+)').firstMatch(raw);
    return match?.group(1)?.trim();
  }
}
