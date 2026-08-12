import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/services/auth_service.dart';
import 'package:ai_saas/core/services/user_service.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:ai_saas/shared/users/user_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _merchantFields = {
  'id': 42,
  'name': 'Merchant',
  'email': 'merchant@example.com',
  'role': 'merchant',
  'created_at': '2026-08-12T00:00:00Z',
};

Map<String, dynamic> _subscription({
  required String type,
  required String status,
  required bool isTrial,
  required bool isEntitled,
  String? startsAt = '2026-08-12T00:00:00Z',
  String? endsAt = '2026-08-26T00:00:00Z',
}) {
  return {
    'type': type,
    'status': status,
    'is_trial': isTrial,
    'is_entitled': isEntitled,
    'starts_at': startsAt,
    'ends_at': endsAt,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      switch (call.method) {
        case 'read':
          return 'session-present';
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
    UserController.instance.currentUserNotifier.value = null;
  });

  test('uses the Laravel /auth/me endpoint for authoritative refreshes', () {
    expect(ApiConstants.authMe, '/auth/me');
    expect(ApiConstants.me, '/profile');
  });

  test('parses an active merchant trial from /me', () {
    final user = UserService.parseProfileResponseForTesting({
      'success': true,
      'data': {
        ..._merchantFields,
        'current_subscription': _subscription(
          type: 'trial',
          status: 'active',
          isTrial: true,
          isEntitled: true,
        ),
      },
    });

    expect(user.role, AppType.merchant);
    expect(user.currentSubscription?.isTrial, isTrue);
    expect(user.currentSubscription?.isEntitled, isTrue);
    expect(user.currentSubscription?.status, 'active');
    expect(user.currentSubscription?.startsAt, isNotNull);
    expect(user.currentSubscription?.endsAt, isNotNull);
    expect(user.currentSubscription?.isExpired, isFalse);
  });

  test('parses an expired merchant trial without using device time', () {
    final user = UserService.parseProfileResponseForTesting({
      'data': {
        ..._merchantFields,
        'current_subscription': _subscription(
          type: 'trial',
          status: 'expired',
          isTrial: true,
          isEntitled: false,
          endsAt: '2099-01-01T00:00:00Z',
        ),
      },
    });

    expect(user.currentSubscription?.isTrial, isTrue);
    expect(user.currentSubscription?.isEntitled, isFalse);
    expect(user.currentSubscription?.isExpired, isTrue);
  });

  test('parses an active paid subscription', () {
    final user = AppUser.fromServerJson({
      ..._merchantFields,
      'current_subscription': _subscription(
        type: 'paid',
        status: 'active',
        isTrial: false,
        isEntitled: true,
        endsAt: '2026-09-12T00:00:00Z',
      ),
    });

    expect(user.currentSubscription?.isPaid, isTrue);
    expect(user.currentSubscription?.isTrial, isFalse);
    expect(user.currentSubscription?.isEntitled, isTrue);
  });

  test('handles null and malformed entitlement dates safely', () {
    final user = AppUser.fromServerJson({
      ..._merchantFields,
      'current_subscription': {
        'type': 'trial',
        'status': 'expired',
        'is_trial': true,
        'is_entitled': false,
        'starts_at': null,
        'ends_at': 'not-a-date',
      },
    });

    expect(user.currentSubscription, isNotNull);
    expect(user.currentSubscription?.startsAt, isNull);
    expect(user.currentSubscription?.endsAt, isNull);
  });

  test('client and admin users cannot receive merchant entitlement state', () {
    for (final role in ['client', 'admin']) {
      final user = AppUser.fromServerJson({
        ..._merchantFields,
        'role': role,
        'current_subscription': _subscription(
          type: 'trial',
          status: 'active',
          isTrial: true,
          isEntitled: true,
        ),
      });

      expect(user.currentSubscription, isNull, reason: role);
    }
  });

  test('local serialization does not cache subscription authority', () {
    final user = AppUser.fromServerJson({
      ..._merchantFields,
      'current_subscription': _subscription(
        type: 'trial',
        status: 'active',
        isTrial: true,
        isEntitled: true,
      ),
    });

    expect(user.toJson().containsKey('current_subscription'), isFalse);

    final restored = AppUser.fromJson({
      ...user.toJson(),
      'current_subscription': _subscription(
        type: 'paid',
        status: 'active',
        isTrial: false,
        isEntitled: true,
      ),
    });
    expect(restored.currentSubscription, isNull);
  });

  test(
      'auth response exposes the new merchant trial immediately after registration',
      () {
    final result = AuthService.parseAuthResultForTesting({
      'data': {
        'token': 'response-token',
        'user': {
          ..._merchantFields,
          'current_subscription': _subscription(
            type: 'trial',
            status: 'active',
            isTrial: true,
            isEntitled: true,
          ),
        },
      },
    });

    expect(result.user.currentSubscription?.isTrial, isTrue);
    expect(result.user.currentSubscription?.isEntitled, isTrue);
  });

  test('session restoration replaces stale local state with latest /me state',
      () async {
    final controller = UserController.instance;
    final restored = await controller.loadSession(
      fetchCurrentUser: () async => UserService.parseProfileResponseForTesting({
        'data': {
          ..._merchantFields,
          'current_subscription': _subscription(
            type: 'trial',
            status: 'expired',
            isTrial: true,
            isEntitled: false,
          ),
        },
      }),
    );

    expect(restored?.currentSubscription?.status, 'expired');
    expect(restored?.currentSubscription?.isEntitled, isFalse);
    expect(controller.currentUser?.currentSubscription?.isExpired, isTrue);
  });
}
