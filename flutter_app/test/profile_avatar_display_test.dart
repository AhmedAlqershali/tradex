import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/screens/profile_screen.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:ai_saas/shared/users/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  tearDown(() {
    UserController.instance.currentUserNotifier.value = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  testWidgets('valid server avatar displays a network image', (tester) async {
    const url = 'https://cdn.example/avatar.jpg';

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileAvatar(photoPath: url),
      ),
    );

    final image = tester.widget<Image>(
      find.byKey(const ValueKey('profile-avatar-network:$url')),
    );
    expect(image.image, isA<NetworkImage>());
    expect((image.image as NetworkImage).url, url);
    expect(find.byKey(const ValueKey('profile-avatar-placeholder')), findsNothing);
  });

  testWidgets('null avatar displays the local placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileAvatar(photoPath: null),
      ),
    );

    expect(
      find.byKey(const ValueKey('profile-avatar-placeholder')),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a local picker path is not treated as the permanent avatar',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileAvatar(
          photoPath: '/data/user/0/cache/picked-avatar.jpg',
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('profile-avatar-placeholder')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(
        'profile-avatar-network:https://cdn.example/avatar.jpg',
      )),
      findsNothing,
    );
  });

  testWidgets('changing the avatar URL rebuilds the displayed image',
      (tester) async {
    final photoPath = ValueNotifier<String?>(
      'https://cdn.example/old-avatar.jpg',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<String?>(
          valueListenable: photoPath,
          builder: (_, value, __) => ProfileAvatar(photoPath: value),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey(
        'profile-avatar-network:https://cdn.example/old-avatar.jpg',
      )),
      findsOneWidget,
    );

    photoPath.value = 'https://cdn.example/new-avatar.jpg';
    await tester.pump();

    expect(
      find.byKey(const ValueKey(
        'profile-avatar-network:https://cdn.example/new-avatar.jpg',
      )),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey(
        'profile-avatar-network:https://cdn.example/old-avatar.jpg',
      )),
      findsNothing,
    );
  });

  testWidgets('session restoration makes the server avatar available to the UI',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      switch (call.method) {
        case 'read':
          return 'restored-session-token';
        case 'deleteAll':
          return true;
        default:
          return null;
      }
    });

    final restoredUser = AppUser.fromServerJson({
      'id': 42,
      'name': 'Restored User',
      'email': 'restored@example.com',
      'role': AppType.client.name,
      'avatar': 'https://cdn.example/restored-avatar.jpg',
    });

    final user = await UserController.instance.loadSession(
      fetchCurrentUser: () async => restoredUser,
    );

    expect(user?.photoPath, restoredUser.photoPath);

    await tester.pumpWidget(
      ValueListenableBuilder<AppUser?>(
        valueListenable: UserController.instance.currentUserNotifier,
        builder: (_, value, __) => MaterialApp(
          home: ProfileAvatar(photoPath: value?.photoPath),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey(
        'profile-avatar-network:https://cdn.example/restored-avatar.jpg',
      )),
      findsOneWidget,
    );
  });

  testWidgets('current user notifier update reaches the profile avatar widget',
      (tester) async {
    final user = ValueNotifier<AppUser?>(
      AppUser.fromServerJson({
        'id': 42,
        'name': 'Profile User',
        'email': 'profile@example.com',
        'role': AppType.client.name,
        'avatar': 'https://cdn.example/old-avatar.jpg',
      }),
    );

    await tester.pumpWidget(
      ValueListenableBuilder<AppUser?>(
        valueListenable: user,
        builder: (_, value, __) => MaterialApp(
          home: ProfileAvatar(photoPath: value?.photoPath),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey(
        'profile-avatar-network:https://cdn.example/old-avatar.jpg',
      )),
      findsOneWidget,
    );

    user.value = AppUser.fromServerJson({
      'id': 42,
      'name': 'Profile User',
      'email': 'profile@example.com',
      'role': AppType.client.name,
      'avatar': 'https://cdn.example/new-avatar.jpg',
    });
    await tester.pump();

    expect(
      find.byKey(const ValueKey(
        'profile-avatar-network:https://cdn.example/new-avatar.jpg',
      )),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey(
      'profile-avatar-network:https://cdn.example/old-avatar.jpg',
    )), findsNothing);
  });
}