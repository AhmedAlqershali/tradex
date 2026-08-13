import 'dart:async';

import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/shared/users/user_controller.dart';
import 'package:ai_saas/shared/users/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

AppUser _user(String name, String photoPath) {
  return AppUser(
    id: 'user-1',
    name: name,
    email: 'user@example.com',
    phone: '',
    role: AppType.client,
    photoPath: photoPath,
    createdAt: DateTime(2026, 8, 13),
  );
}

void main() {
  final controller = UserController.instance;

  tearDown(() {
    controller.currentUserNotifier.value = null;
  });

  test('ignores an older refresh after a profile mutation starts', () async {
    final oldUser = _user(
      'Old profile',
      'https://cdn.example/old-avatar.jpg',
    );
    final newUser = _user(
      'Updated profile',
      'https://cdn.example/new-avatar.jpg',
    );
    final pendingRefresh = Completer<AppUser>();

    controller.currentUserNotifier.value = oldUser;
    final refresh = controller.refreshProfileIfCurrent(
      fetchCurrentUser: () => pendingRefresh.future,
    );

    // updateProfile invalidates refreshes before awaiting any mutation work.
    await controller.updateProfile(photoPath: newUser.photoPath);
    controller.currentUserNotifier.value = newUser;

    pendingRefresh.complete(oldUser);

    expect(await refresh, isNull);
    expect(controller.currentUser, same(newUser));
  });

  test('accepts a normal refresh when no profile mutation starts', () async {
    final refreshedUser = _user(
      'Refreshed profile',
      'https://cdn.example/refreshed-avatar.jpg',
    );

    final result = await controller.refreshProfileIfCurrent(
      fetchCurrentUser: () async => refreshedUser,
    );

    expect(result, same(refreshedUser));
    expect(controller.currentUser, same(refreshedUser));
  });
}