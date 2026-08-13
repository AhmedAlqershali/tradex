import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Temporary, debug-only avatar tracing.
///
/// Remove this file and its call sites after one production upload has been
/// diagnosed. It never logs image bytes, request headers, response bodies,
/// credentials, cookies, or full local file paths.
class AvatarDiagnostics {
  AvatarDiagnostics._();

  static bool _active = false;
  static final Set<String> _probedUrls = <String>{};

  static void begin() {
    if (!kDebugMode) return;
    _active = true;
    _probedUrls.clear();
    debugPrint('[AVATAR_TRACE_BEGIN]');
  }

  static void end() {
    if (!kDebugMode || !_active) return;
    debugPrint('[AVATAR_TRACE_END]');
    _active = false;
  }

  static Future<void> logSelectedFile({
    required String path,
    required String name,
    required int size,
    required String? mimeType,
    required Future<List<int>> Function() readBytes,
  }) async {
    if (!kDebugMode || !_active) return;

    try {
      final bytes = await readBytes();
      final hash = sha256.convert(bytes);
      debugPrint(
        '[AVATAR_TRACE] selected_file '
        'name=${_safeName(name, path)} '
        'size=$size '
        'mime_type=${mimeType ?? 'unknown'} '
        'sha256=$hash',
      );
    } catch (_) {
      debugPrint(
        '[AVATAR_TRACE] selected_file '
        'name=${_safeName(name, path)} read_failed=true',
      );
    }
  }

  static void logUploadRequest({
    required String endpoint,
    required String fieldName,
  }) {
    if (!kDebugMode || !_active) return;
    debugPrint(
      '[AVATAR_TRACE] upload '
      'endpoint=$endpoint field_name=$fieldName',
    );
  }

  static void logUploadResult({
    required bool success,
    required int? status,
    String? avatar,
  }) {
    if (!kDebugMode || !_active) return;
    debugPrint(
      '[AVATAR_TRACE] upload_result '
      'success=$success '
      'http_status=${status ?? 'unknown'} '
      'response_avatar=${avatar == null ? 'null' : redactUrl(avatar)}',
    );
  }

  static void logModelPhotoPath(String? photoPath) {
    if (!kDebugMode || !_active) return;
    debugPrint(
      '[AVATAR_TRACE] model '
      'AppUser.photoPath=${photoPath == null ? 'null' : redactUrl(photoPath)}',
    );
  }

  static void logState(String stage, String? photoPath) {
    if (!kDebugMode || !_active) return;
    debugPrint(
      '[AVATAR_TRACE] state '
      'stage=$stage '
      'currentUserNotifier.photoPath='
      '${photoPath == null ? 'null' : redactUrl(photoPath)}',
    );
  }

  static void logProfileProvider({
    required String provider,
    String? resolvedUrl,
  }) {
    if (!kDebugMode || !_active) return;
    debugPrint(
      '[AVATAR_TRACE] profile '
      'image_provider=$provider '
      'resolved_url=${resolvedUrl == null ? 'null' : redactUrl(resolvedUrl)}',
    );
  }

  /// Performs a diagnostic-only public GET; the app's Image.network behavior
  /// remains unchanged. Image bytes are hashed but never printed.
  static Future<void> probeDownload(String url) async {
    if (!kDebugMode || !_active || !_probedUrls.add(url)) return;

    final safeUrl = redactUrl(url);
    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final bytes = await response.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      final contentType = response.headers.contentType?.mimeType ?? 'unknown';
      debugPrint(
        '[AVATAR_TRACE] download '
        'url=$safeUrl '
        'http_status=${response.statusCode} '
        'content_type=$contentType '
        'size=${bytes.length} '
        'sha256=${sha256.convert(bytes)}',
      );
    } catch (_) {
      debugPrint(
        '[AVATAR_TRACE] download '
        'url=$safeUrl http_status=unavailable',
      );
    } finally {
      client?.close(force: true);
    }
  }

  static void log(
    String stage,
    Object? value, {
    String? provider,
    bool? widgetReceivesUser,
    String? error,
  }) {
    if (!kDebugMode) return;

    final summary = describe(value);
    final details = <String>[
      'avatar=$summary',
      if (provider != null) 'provider=$provider',
      if (widgetReceivesUser != null)
        'widget_receives_updated_user=$widgetReceivesUser',
      if (error != null) 'network_error=$error',
    ];
    debugPrint('[avatar-trace] $stage ${details.join(' ')}');
  }

  static String redactUrl(String value) {
    final parsed = Uri.tryParse(value.trim());
    if (parsed == null) return value.split('?').first;
    if (!parsed.hasScheme || parsed.host.isEmpty) {
      return parsed.path.isEmpty ? value.split('?').first : parsed.path;
    }

    return Uri(
      scheme: parsed.scheme,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
      path: parsed.path,
    ).toString();
  }

  static String describe(Object? value) {
    if (value == null) {
      return 'exists=false type=null format=missing absolute=false';
    }

    final type = value.runtimeType;
    if (value is! String) {
      return 'exists=true type=$type format=non_string absolute=false';
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'exists=false type=String format=empty absolute=false';
    }

    final uri = Uri.tryParse(trimmed);
    final hasScheme = uri != null && uri.hasScheme && uri.host.isNotEmpty;
    final isHttp =
        hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    final format = isHttp
        ? 'absolute_http'
        : trimmed.startsWith('/storage/')
            ? 'root_relative_storage'
            : trimmed.startsWith('/')
                ? 'local_or_root_path'
                : hasScheme
                    ? 'absolute_non_http'
                    : 'other';

    return 'exists=true type=String format=$format absolute=$hasScheme';
  }

  static String _safeName(String name, String path) {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) return trimmedName;
    return path.split(RegExp(r'[\\/]')).last;
  }
}