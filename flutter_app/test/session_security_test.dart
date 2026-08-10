import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/shared/users/user_controller.dart';

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

  test('legacy local identity cannot restore an authenticated session', () async {
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
}