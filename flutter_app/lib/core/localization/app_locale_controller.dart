import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleController {
  AppLocaleController._();

  static final AppLocaleController instance = AppLocaleController._();
  static const _storageKey = 'tradex_locale';
  static const _defaultLocale = Locale('ar');

  final ValueNotifier<Locale> localeNotifier = ValueNotifier(_defaultLocale);

  Locale get locale => localeNotifier.value;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCode = preferences.getString(_storageKey);
    if (savedCode == 'ar' || savedCode == 'en') {
      localeNotifier.value = Locale(savedCode!);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'ar' && locale.languageCode != 'en') return;
    localeNotifier.value = Locale(locale.languageCode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, locale.languageCode);
  }

  @visibleForTesting
  void resetForTesting() {
    localeNotifier.value = _defaultLocale;
  }
}
