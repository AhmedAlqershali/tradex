import 'package:flutter/foundation.dart';

/// Debug-only, non-sensitive avatar tracing.
///
/// This deliberately reports shape and selection decisions, never URL values,
/// response bodies, user fields, or authentication context.
class AvatarDiagnostics {
  AvatarDiagnostics._();

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
    final isHttp = hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
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
}