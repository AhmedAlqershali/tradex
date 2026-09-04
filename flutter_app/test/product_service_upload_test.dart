import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/core/services/product_service.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('product-upload-test-');
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  Future<String> createImageFile(String name) async {
    final file = File('${temporaryDirectory.path}/$name');
    await file.writeAsBytes([0, 1, 2, 3]);
    return file.path;
  }

  test('adds one selected image as an images[] multipart field', () async {
    final imagePath = await createImageFile('one.jpg');

    final formData = await buildProductMultipartFormData({}, [imagePath]);

    expect(formData.files, hasLength(1));
    expect(formData.files.single.key, 'images[]');
  });

  test('adds every selected image as a separate images[] multipart field', () async {
    final imagePaths = [
      await createImageFile('one.jpg'),
      await createImageFile('two.jpg'),
      await createImageFile('three.jpg'),
    ];

    final formData = await buildProductMultipartFormData({}, imagePaths);

    expect(formData.files, hasLength(3));
    expect(formData.files.map((entry) => entry.key), everyElement('images[]'));
  });

  test('adds no multipart files when no images are selected', () async {
    final formData = await buildProductMultipartFormData({'name': 'No image'}, []);

    expect(formData.files, isEmpty);
    expect(formData.fields.single.value, 'No image');
  });
}