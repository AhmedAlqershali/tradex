import 'package:ai_saas/core/api/app_config.dart';
import 'package:ai_saas/core/services/category_service.dart';
import 'package:ai_saas/screens/client/categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves and resolves a category image during API mapping', () {
    final option = CategoryOption.fromServerJson({
      'id': 7,
      'name': 'Electronics',
      'image': '/storage/categories/electronics.jpg',
    });

    expect(option.imageUrl,
        AppConfig.resolveMediaUrl('/storage/categories/electronics.jpg'));
    expect(option.imageUrl, contains('/storage/categories/electronics.jpg'));
  });

  test('normalizes category image URLs to the production media origin without duplicate storage', () {
    final option = CategoryOption.fromServerJson({
      'id': 9,
      'name': 'Home',
      'image': 'https://tradex-v2us.onrender.com/api/v1/storage/categories/home.jpg',
    });

    expect(
      option.imageUrl,
      'https://tradex-v2us.onrender.com/storage/categories/home.jpg',
    );
    expect(option.imageUrl, isNot(contains('/api/v1/storage/')));
    expect(option.imageUrl, isNot(contains('/storage/storage/')));
  });

  testWidgets('category without an image uses the existing icon fallback',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryImage(
            imageUrl: null,
            fallbackIcon: Icons.devices,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.devices), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('category with an image creates a network image',
      (tester) async {
    final option = CategoryOption.fromServerJson({
      'id': 8,
      'name': 'Fashion',
      'image': '/storage/categories/fashion.jpg',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryImage(
            imageUrl: option.imageUrl,
            fallbackIcon: Icons.checkroom,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, option.imageUrl);
  });
}