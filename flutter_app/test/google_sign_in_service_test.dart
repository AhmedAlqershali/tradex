import 'package:ai_saas/core/services/google_sign_in_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGoogleIdentityProvider implements GoogleIdentityProvider {
  _FakeGoogleIdentityProvider(this.result);

  final Future<String?> Function() result;

  @override
  Future<String?> signInForIdToken() => result();
}

void main() {
  group('GoogleSignInService', () {
    test('returns the ID token from the injected provider', () async {
      final service = GoogleSignInService(
        provider: _FakeGoogleIdentityProvider(() async => 'id-token'),
      );

      expect(await service.signIn(), 'id-token');
    });

    test('returns null when the user cancels account selection', () async {
      final service = GoogleSignInService(
        provider: _FakeGoogleIdentityProvider(() async => null),
      );

      expect(await service.signIn(), isNull);
    });

    test('rejects an empty token as an authentication failure', () async {
      final service = GoogleSignInService(
        provider: _FakeGoogleIdentityProvider(() async => ''),
      );

      expect(
        () => service.signIn(),
        throwsA(isA<GoogleSignInException>()),
      );
    });

    test('maps native cancellation to a cancellable result', () async {
      final service = GoogleSignInService(
        provider: _FakeGoogleIdentityProvider(
          () => Future<String?>.error(
            PlatformException(code: 'sign_in_canceled'),
          ),
        ),
      );

      expect(await service.signIn(), isNull);
    });

    test('maps native authentication failures to a user-facing error',
        () async {
      final service = GoogleSignInService(
        provider: _FakeGoogleIdentityProvider(
          () => Future<String?>.error(
            PlatformException(code: 'failed_to_recover_auth'),
          ),
        ),
      );

      expect(
        () => service.signIn(),
        throwsA(
          isA<GoogleSignInException>().having(
            (error) => error.message,
            'message',
            contains('تعذر إكمال تسجيل الدخول'),
          ),
        ),
      );
    });
  });
}