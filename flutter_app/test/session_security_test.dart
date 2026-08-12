import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:ai_saas/shared/users/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      switch (call.method) {
        case 'read':
          return null;
        case 'deleteAll':
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
