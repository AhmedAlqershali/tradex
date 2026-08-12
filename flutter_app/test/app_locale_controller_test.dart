import 'package:ai_saas/core/localization/app_locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final controller = AppLocaleController.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller.resetForTesting();
  });

  test('switches language immediately and persists the selected code',
      () async {
    await controller.setLocale(const Locale('en'));

    expect(controller.locale, const Locale('en'));
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('tradex_locale'), 'en');
  });

  test('restores the saved language after loading', () async {
    SharedPreferences.setMockInitialValues({'tradex_locale': 'en'});

    await controller.load();

    expect(controller.locale, const Locale('en'));
  });

  test('keeps Arabic as the default when no language is saved', () async {
    await controller.load();

    expect(controller.locale, const Locale('ar'));
  });
}
