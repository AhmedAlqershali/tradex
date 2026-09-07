import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'ai_result_model.dart';

// ─── AI Controller ────────────────────────────────────────────────────────────
//
// Singleton controller for all AI generation features. Calls the real
// backend AI endpoints:
//   POST /ai/product-description  { context, language }
//   POST /ai/marketing-content    { context, language } — generates marketing
//                                    content for the selected product.
//   POST /ai/customer-reply       { context, language, store_name }
//
// ─────────────────────────────────────────────────────────────────────────────

class AiRuntimeFailure implements Exception {
  const AiRuntimeFailure({required this.stage, required this.cause});

  final String stage;
  final Object cause;

  @override
  String toString() => cause.toString();
}

class AiController {
  AiController._();
  static final AiController instance = AiController._();

  static const String subscriptionRequiredMessage =
      'يلزم وجود اشتراك نشط لاستخدام أدوات Tradex AI. يرجى الاشتراك للمتابعة.';

  static bool isSubscriptionRequiredError(Object error) {
    final cause = error is AiRuntimeFailure ? error.cause : error;
    if (cause is ForbiddenException) {
      final normalized = cause.message.toLowerCase();
      return normalized.contains('active trial or paid subscription') ||
          normalized.contains('subscription is required') ||
          normalized.contains('requires an active') ||
          normalized.contains('اشتراك') && normalized.contains('مطلوب');
    }
    if (cause is String) {
      final normalized = cause.toLowerCase();
      return normalized.contains('active trial or paid subscription') ||
          normalized.contains('subscription is required') ||
          normalized.contains('requires an active') ||
          normalized.contains('اشتراك') && normalized.contains('مطلوب');
    }
    return false;
  }

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
      request: () {
        if (kDebugMode) debugPrint('[AI_RUNTIME] calling _post');
        return _post(ApiConstants.aiProductDescription, context);
      },
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
      request: () {
        if (kDebugMode) debugPrint('[AI_RUNTIME] calling _post');
        return _post(
          ApiConstants.aiMarketingContent,
          context,
        );
      },
    );
  }

  /// Generates a professional reply to a customer's message.
  Future<AiResult> generateCustomerReply({
    required String customerMessage,
  }) {
    return _generate(
      tool: AiToolType.customerReply,
      prompt: customerMessage,
      request: () {
        if (kDebugMode) debugPrint('[AI_RUNTIME] calling _post');
        return _post(
          ApiConstants.aiCustomerReply,
          customerMessage,
          storeName: UserController.instance.currentUser?.storeName,
        );
      },
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
    if (kDebugMode) debugPrint('[AI_RUNTIME] controller _generate entered');
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
    } on AiRuntimeFailure {
      statusNotifier.value = AiStatus.error;
      rethrow;
    } on ApiException catch (error) {
      if (kDebugMode) debugPrint('[AI_RUNTIME] controller ApiException: ${error.runtimeType}: $error');
      statusNotifier.value = AiStatus.error;
      rethrow;
    } catch (error) {
      if (kDebugMode) debugPrint('[AI_RUNTIME] controller error: ${error.runtimeType}: $error');
      // Catch-all: ensures statusNotifier always reaches a terminal state even
      // for non-API errors (network timeout, type cast failures, etc.).
      // Without this, the AI tool sheet spinner hangs indefinitely.
      statusNotifier.value = AiStatus.error;
      throw AiRuntimeFailure(stage: 'before ApiClient.post', cause: error);
    }
  }

  // ── Backend calls ─────────────────────────────────────────────────────────────

  /// POST to an /ai/* endpoint with the standard {context, language} body
  /// and returns the raw `result` text.
  /// The backend requires `context` to be at least 5 characters — very short
  /// merchant input is padded so the request doesn't fail validation for a
  /// reason the user can't see.
  Future<String> _post(
    String path,
    String context, {
    String? storeName,
  }) async {
    if (kDebugMode) debugPrint('[AI_RUNTIME] _post entered path=$path');
    final trimmed = context.trim();
    final safeContext = trimmed;
    var stage = 'before ApiClient.post';
    try {
      if (kDebugMode) {
        debugPrint('[AI_RUNTIME] calling ApiClient.post path=$path baseUrl=${ApiConstants.baseUrl}');
      }
      stage = 'inside ApiClient/Dio';
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        path,
        data: {
          'context': safeContext,
          'language': _detectLanguage(safeContext),
          if (storeName != null && storeName.isNotEmpty) 'store_name': storeName,
        },
      );
      stage = 'after HTTP response';
      final raw = response.data;
      if (raw == null) {
        throw const UnknownException(
          'خادم الذكاء الاصطناعي أعاد استجابة غير صالحة. حاول مجدداً.',
        );
      }
      final body =
          raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
      final result = body['result'];
      if (result is! String || result.trim().isEmpty) {
        throw const UnknownException(
          'خادم الذكاء الاصطناعي أعاد نتيجة فارغة أو غير صالحة. حاول مجدداً.',
        );
      }
      final cleaned = _cleanResponse(result);
      if (cleaned.isEmpty) {
        throw const UnknownException(
          'خادم الذكاء الاصطناعي أعاد نتيجة فارغة أو غير قابلة للعرض. حاول مجدداً.',
        );
      }
      return cleaned;
    } on AiRuntimeFailure {
      rethrow;
    } catch (error) {
      throw AiRuntimeFailure(stage: stage, cause: error);
    }
  }

  String _detectLanguage(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text) ? 'Arabic' : 'English';
  }

  String _cleanResponse(String value) {
    var text = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    text = text.replaceAll(RegExp(r'^```(?:json|text|markdown)?\s*|\s*```$', caseSensitive: false), '');
    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
    if (jsonMatch != null) {
      try {
        final decoded = jsonDecode(jsonMatch.group(0)!);
        if (decoded is Map<String, dynamic>) {
          final nested = decoded['result'] ?? decoded['content'] ?? decoded['text'] ?? decoded['output'];
          text = nested is String ? nested.trim() : '';
        }
      } catch (_) {
        // Keep the provider text when it is not valid JSON.
      }
    }
    text = text.replaceAll(RegExp(r'\(\s*in\s+(?:Arabic|English)\s*\)', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'^\s*(?:final\s+answer|answer|output|response)\s*:\s*', caseSensitive: false, multiLine: true), '');
    final lines = text.split('\n').where((line) {
      return !RegExp(r'^\s*(?:system|developer|internal|user)\s+(?:prompt|instructions?)\s*:', caseSensitive: false).hasMatch(line) &&
          !RegExp(r'^\s*(?:prompt|instructions?)\s*:\s*', caseSensitive: false).hasMatch(line) &&
          !RegExp(r'^\s*(?:evaluate input facts(?:\s+vs\.?\s+constraints)?|analyze input|constraints|system prompt|developer instruction|internal reasoning)\s*:?\s*', caseSensitive: false).hasMatch(line);
    });
    return lines.join('\n').trim();
  }

}
