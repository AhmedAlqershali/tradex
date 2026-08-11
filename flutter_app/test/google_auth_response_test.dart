import 'package:ai_saas/core/services/auth_service.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the Google auth Sanctum envelope and user role', () {
    final result = AuthService.parseAuthResultForTesting({
      'data': {
        'token': 'sanctum-token',
        'user': {
          'id': 'user-1',
          'name': 'Google User',
          'email': 'google@example.com',
          'phone': '',
          'role': 'client',
          'created_at': '2026-08-11T00:00:00Z',
        },
      },
    });

    expect(result.tokens.accessToken, 'sanctum-token');
    expect(result.user.id, 'user-1');
    expect(result.user.email, 'google@example.com');
    expect(result.user.role, AppType.client);
  });

  test('rejects a Google auth response without a Sanctum token', () {
    expect(
      () => AuthService.parseAuthResultForTesting({
        'data': {
          'user': {
            'id': 'user-1',
            'name': 'Google User',
            'email': 'google@example.com',
            'phone': '',
            'role': 'client',
          },
        },
      }),
      throwsA(isA<Exception>()),
    );
  });
}