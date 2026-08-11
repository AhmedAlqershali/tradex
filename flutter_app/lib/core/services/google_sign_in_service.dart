import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The smallest platform seam needed by the auth BLoC.
///
/// Keeping Google account selection behind this interface means auth tests can
/// use deterministic fake credentials and never open a native account picker.
abstract interface class GoogleIdentityProvider {
  Future<String?> signInForIdToken();
}

/// User-facing failure from the native Google account flow.
class GoogleSignInException implements Exception {
  const GoogleSignInException(this.message);

  final String message;

  @override
  String toString() => 'GoogleSignInException: $message';
}

/// Adapter around the official Google Sign-In plugin.
class GoogleSignInService {
  GoogleSignInService({GoogleIdentityProvider? provider})
      : _provider = provider ?? _GoogleIdentityProvider();

  static final GoogleSignInService instance = GoogleSignInService();

  final GoogleIdentityProvider _provider;

  /// Opens native account selection and returns the ID token Laravel verifies.
  ///
  /// A user cancellation is represented by null and is intentionally not an
  /// error. Empty tokens are treated as configuration/authentication failures.
  Future<String?> signIn() async {
    try {
      final token = await _provider.signInForIdToken();
      if (token == null) return null;
      if (token.trim().isEmpty) {
        throw const GoogleSignInException(
          'تعذر الحصول على بيانات اعتماد Google. حاول مرة أخرى.',
        );
      }
      return token;
    } on GoogleSignInException {
      rethrow;
    } on PlatformException catch (error) {
      if (error.code == GoogleSignIn.kSignInCanceledError) return null;
      throw GoogleSignInException(_messageForPlatformError(error));
    } catch (_) {
      throw const GoogleSignInException(
        'تعذر الاتصال بخدمة تسجيل الدخول عبر Google. حاول مرة أخرى.',
      );
    }
  }

  static String _messageForPlatformError(PlatformException error) {
    switch (error.code) {
      case GoogleSignIn.kNetworkError:
        return 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.';
      case GoogleSignIn.kSignInCanceledError:
        // The official plugin normally converts this to null. Keep this
        // mapping for injected/platform implementations that surface it.
        return 'تم إلغاء تسجيل الدخول عبر Google.';
      case 'user_recoverable_auth':
      case 'failed_to_recover_auth':
        return 'تعذر إكمال تسجيل الدخول عبر Google. حاول مرة أخرى.';
      default:
        return 'تعذر تسجيل الدخول عبر Google. تحقق من إعدادات الحساب وحاول مرة أخرى.';
    }
  }
}

class _GoogleIdentityProvider implements GoogleIdentityProvider {
  _GoogleIdentityProvider()
      : _googleSignIn = GoogleSignIn(
          scopes: const ['email'],
          // This is a public OAuth client ID, not a secret. It is supplied by
          // Codemagic/Replit at build time so no Google project value is
          // invented or committed to source control.
          serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
        );

  static const String _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  final GoogleSignIn _googleSignIn;

  @override
  Future<String?> signInForIdToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final authentication = await account.authentication;
    return authentication.idToken;
  }
}