import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/screens/auth/new_password_screen.dart';
import 'package:ai_saas/core/services/fcm_service.dart';

class PasswordResetLinkData {
  const PasswordResetLinkData({required this.email, required this.token});

  final String email;
  final String token;
}

class PasswordResetLinkParser {
  static PasswordResetLinkData? parse(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    final path = uri.path.toLowerCase();
    final isResetPath = path.endsWith('/auth/password/reset') ||
        path.endsWith('/password/reset') ||
        path.contains('/auth/password/reset');
    if (!isResetPath) return null;

    final email = uri.queryParameters['email']?.trim();
    final token = uri.queryParameters['token']?.trim();
    if (email == null || email.isEmpty || token == null || token.isEmpty) {
      return null;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return null;
    }

    return PasswordResetLinkData(email: email, token: token);
  }
}

class DeepLinkService {
  DeepLinkService._();
  static final instance = DeepLinkService._();

  final MethodChannel _channel = const MethodChannel('ps.tradex.app/deeplink');
  final Set<String> _handledLinks = <String>{};
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler(_handleMethodCall);

    final initialLink = await _channel.invokeMethod<String?>('getInitialLink');
    if (initialLink != null && initialLink.isNotEmpty) {
      await _handleLink(initialLink);
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onLink' && call.arguments is String) {
      await _handleLink(call.arguments as String);
    }
  }

  Future<void> _handleLink(String rawLink) async {
    if (rawLink.trim().isEmpty) return;

    final normalized = rawLink.trim();
    if (!_handledLinks.add(normalized)) return;

    final payload = PasswordResetLinkParser.parse(normalized);
    if (payload == null) return;

    final navigator = FcmService.instance.navigatorKey.currentState;
    if (navigator == null || !navigator.mounted) return;

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => NewPasswordScreen(
          type: AppType.client,
          email: payload.email,
          token: payload.token,
        ),
      ),
    );
  }
}
