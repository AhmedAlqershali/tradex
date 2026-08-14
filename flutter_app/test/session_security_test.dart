import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/storage/secure_storage_service.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:ai_saas/shared/users/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final secureStorageValues = <String, String>{};

  setUp(() {
    secureStorageValues.clear();
    UserController.instance.currentUserNotifier.value = null;
    UserController.instance.authErrorNotifier.value = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      final arguments = call.arguments is Map
          ? Map<dynamic, dynamic>.from(call.arguments as Map)
          : const <dynamic, dynamic>{};
      switch (call.method) {
        case 'read':
          return secureStorageValues[arguments['key']];
        case 'write':
          secureStorageValues[arguments['key'] as String] =
              arguments['value'] as String;
          return true;
        case 'delete':
          secureStorageValues.remove(arguments['key']);
          return true;
        case 'deleteAll':
          secureStorageValues.clear();
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  Future<void> expectTemporaryRestorationFailure(
    ApiException exception,
  ) async {
    await SecureStorageService.instance.saveAccessToken('temporary-token');

    final restored = await UserController.instance.loadSession(
      fetchCurrentUser: () async => throw exception,
    );

    expect(restored, isNull);
    expect(UserController.instance.currentUser, isNull);
    expect(secureStorageValues['tradex_access_token'], 'temporary-token');
    expect(
      UserController.instance.authErrorNotifier.value,
      isNot(contains('انتهت جلستك')),
    );
  }

  test('legacy local identity cannot restore an authenticated session',
      () async {
    SharedPreferences.setMockInitialValues({
      'tradex_user_session': '''
        {
          "id": "attacker-controlled-id",
          "name": "Local User",
          "email": "local@example.com",
          "phone": "000",
          "role": "admin",
          "createdAt": "2026-01-01T00:00:00.000Z"
        }
      ''',
    });

    final user = await UserController.instance.loadSession();

    expect(user, isNull);
    expect(UserController.instance.currentUser, isNull);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('tradex_user_session'), isFalse);
  });

  test('successful /auth/me restoration hydrates the authenticated user',
      () async {
    await SecureStorageService.instance.saveAccessToken('restoration-token');
    final expectedUser = AppUser.fromServerJson({
      'id': 41,
      'name': 'Restored User',
      'email': 'restored@example.com',
      'phone': '0501234567',
      'role': 'merchant',
      'current_subscription': {
        'type': 'trial',
        'status': 'active',
        'is_trial': true,
        'is_entitled': true,
      },
    });

    final restored = await UserController.instance.loadSession(
      fetchCurrentUser: () async => expectedUser,
    );

    expect(restored, same(expectedUser));
    expect(UserController.instance.currentUser, same(expectedUser));
    expect(secureStorageValues['tradex_access_token'], 'restoration-token');
  });

  test('401 restoration clears authentication and reports session expiry',
      () async {
    await SecureStorageService.instance.saveAccessToken('expired-token');

    final restored = await UserController.instance.loadSession(
      fetchCurrentUser: () async => throw const AuthException(),
    );

    expect(restored, isNull);
    expect(UserController.instance.currentUser, isNull);
    expect(secureStorageValues, isEmpty);
    expect(
      UserController.instance.authErrorNotifier.value,
      contains('انتهت جلستك'),
    );
  });

  test('403 restoration preserves the stored authentication token', () async {
    await expectTemporaryRestorationFailure(
      const ForbiddenException(),
    );
  });

  test('422 restoration preserves the stored authentication token', () async {
    await expectTemporaryRestorationFailure(
      const ValidationException('Validation failed.'),
    );
  });

  test('429 restoration preserves the stored authentication token', () async {
    await expectTemporaryRestorationFailure(
      const ServerException('Too many requests.', statusCode: 429),
    );
  });

  test('500 restoration preserves the stored authentication token', () async {
    await expectTemporaryRestorationFailure(
      const ServerException('Server failure.', statusCode: 500),
    );
  });

  test('timeout restoration preserves the stored authentication token',
      () async {
    await expectTemporaryRestorationFailure(const TimeoutException());
  });

  test('network restoration preserves the stored authentication token',
      () async {
    await expectTemporaryRestorationFailure(const NetworkException());
  });

  test('explicit logout clears authentication storage and user state',
      () async {
    await SecureStorageService.instance.saveAccessToken('logout-token');
    await UserController.instance.setUser(AppUser.fromServerJson({
      'id': 42,
      'name': 'Logged In User',
      'email': 'user@example.com',
      'role': 'client',
    }));

    await UserController.instance.logout(performLogout: () async {});

    expect(secureStorageValues, isEmpty);
    expect(UserController.instance.currentUser, isNull);
  });

  test('logout then login replaces merchant entitlement with the next user',
      () async {
    final controller = UserController.instance;
    final merchant = AppUser.fromServerJson({
      'id': 41,
      'name': 'Merchant',
      'email': 'merchant@example.com',
      'role': 'merchant',
      'current_subscription': {
        'type': 'trial',
        'status': 'active',
        'is_trial': true,
        'is_entitled': true,
      },
    });
    final client = AppUser.fromServerJson({
      'id': 42,
      'name': 'Client',
      'email': 'client@example.com',
      'role': 'client',
    });

    await controller.setUser(merchant);
    await controller.logout(performLogout: () async {});
    await controller.setUser(client);

    expect(controller.currentUser?.id, '42');
    expect(controller.currentUser?.role, AppType.client);
    expect(controller.currentUser?.currentSubscription, isNull);
  });
}
