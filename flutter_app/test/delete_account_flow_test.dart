import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/storage/secure_storage_service.dart';
import 'package:ai_saas/screens/onboarding_screen.dart';
import 'package:ai_saas/screens/profile_screen.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:ai_saas/shared/users/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('delete-account action is visible and opens confirmation dialog', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    expect(find.text('Delete Account'), findsOneWidget);
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete account permanently?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('cancellation does not trigger account deletion', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete account permanently?'), findsNothing);
  });

  test('successful deletion clears the local session', () async {
    const secureStorageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    final secureStorageValues = <String, String>{};

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

    await SecureStorageService.instance.saveAccessToken('access-token');
    await SecureStorageService.instance.saveRefreshToken('refresh-token');
    final user = AppUser.fromServerJson({
      'id': 'user-1',
      'name': 'Current User',
      'email': 'user@example.com',
      'phone': '0500000000',
      'role': 'client',
    });
    UserController.instance.currentUserNotifier.value = user;
    UserController.instance.authErrorNotifier.value = 'stale error';

    await UserController.instance.deleteAccount(performDelete: () async {});

    expect(secureStorageValues, isEmpty);
    expect(UserController.instance.currentUser, isNull);
    expect(UserController.instance.authErrorNotifier.value, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('tradex_user_session'), isFalse);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  test('failed deletion preserves the local session', () async {
    const secureStorageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    final secureStorageValues = <String, String>{};

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

    await SecureStorageService.instance.saveAccessToken('access-token');
    await SecureStorageService.instance.saveRefreshToken('refresh-token');
    final user = AppUser.fromServerJson({
      'id': 'user-2',
      'name': 'Logged In User',
      'email': 'user@example.com',
      'phone': '0500000000',
      'role': 'client',
    });
    UserController.instance.currentUserNotifier.value = user;
    UserController.instance.authErrorNotifier.value = 'stale error';

    await expectLater(
      UserController.instance.deleteAccount(
        performDelete: () async => throw const ServerException(
          'Delete failed.',
          statusCode: 500,
        ),
      ),
      throwsA(isA<ServerException>()),
    );

    expect(secureStorageValues['tradex_access_token'], 'access-token');
    expect(secureStorageValues['tradex_refresh_token'], 'refresh-token');
    expect(UserController.instance.currentUser, same(user));
    expect(UserController.instance.authErrorNotifier.value, 'stale error');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });
}
