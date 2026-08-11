import 'package:ai_saas/core/api/app_config.dart';
import 'package:ai_saas/core/services/user_service.dart';
import 'package:ai_saas/models/app_type.dart';
import 'package:ai_saas/shared/models/store_model.dart';
import 'package:ai_saas/shared/users/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('profile contract parsing', () {
    test('parses the standard profile envelope and absolute avatar URL', () {
      final user = UserService.parseProfileResponseForTesting({
        'success': true,
        'data': {
          'id': 42,
          'name': 'Saved Name',
          'email': 'saved@example.com',
          'phone': null,
          'role': 'client',
          'avatar': 'https://cdn.example/avatar.jpg',
          'created_at': '2026-08-11T00:00:00Z',
        },
      });

      expect(user.id, '42');
      expect(user.name, 'Saved Name');
      expect(user.email, 'saved@example.com');
      expect(user.phone, '');
      expect(user.role, AppType.client);
      expect(user.photoPath, 'https://cdn.example/avatar.jpg');
    });

    test('resolves root-relative and local Laravel avatar URLs', () {
      final relative = AppUser.fromServerJson({
        'id': 1,
        'role': 'client',
        'avatar': '/storage/avatars/a.jpg',
      });
      final local = AppUser.fromServerJson({
        'id': 2,
        'role': 'client',
        'avatar': 'http://localhost/storage/avatars/b.jpg',
      });

      expect(relative.photoPath,
          AppConfig.resolveMediaUrl('/storage/avatars/a.jpg'));
      expect(
          local.photoPath, AppConfig.resolveMediaUrl('/storage/avatars/b.jpg'));
      expect(local.photoPath, isNot(contains('localhost')));
    });

    test('maps the Laravel store_name and logo contract', () {
      final store = StoreModel.fromServerJson({
        'id': 7,
        'store_name': 'Saved Store',
        'description': 'Description',
        'logo': '/storage/logos/store.jpg',
      });

      expect(store.id, '7');
      expect(store.title, 'Saved Store');
      expect(store.subTitle, 'Description');
      expect(store.imageUrl,
          AppConfig.resolveMediaUrl('/storage/logos/store.jpg'));
    });
  });
}
