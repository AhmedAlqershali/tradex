import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get isArabic => locale.languageCode == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  String get defaultUser => _value('defaultUser');
  String get settings => _value('settings');
  String get editProfile => _value('editProfile');
  String get changePassword => _value('changePassword');
  String get notifications => _value('notifications');
  String get language => _value('language');
  String get languageArabic => _value('languageArabic');
  String get languageEnglish => _value('languageEnglish');
  String get favorites => _value('favorites');
  String get noFavorites => _value('noFavorites');
  String get logout => _value('logout');
  String get loggingOut => _value('loggingOut');
  String get passwordCurrent => _value('passwordCurrent');
  String get passwordNew => _value('passwordNew');
  String get passwordConfirm => _value('passwordConfirm');
  String get passwordDescription => _value('passwordDescription');
  String get showPassword => _value('showPassword');
  String get hidePassword => _value('hidePassword');
  String get passwordSave => _value('passwordSave');
  String get passwordCancel => _value('passwordCancel');
  String get passwordChanged => _value('passwordChanged');
  String get passwordSuccessDescription => _value('passwordSuccessDescription');
  String get passwordBackToProfile => _value('passwordBackToProfile');
  String get passwordRequired => _value('passwordRequired');
  String get passwordMinLength => _value('passwordMinLength');
  String get passwordMismatch => _value('passwordMismatch');
  String get sessionExpired => _value('sessionExpired');
  String get forbidden => _value('forbidden');
  String get serverError => _value('serverError');
  String get networkError => _value('networkError');
  String get timeoutError => _value('timeoutError');
  String get unexpectedError => _value('unexpectedError');
  String get home => _value('home');
  String get search => _value('search');
  String get categories => _value('categories');
  String get account => _value('account');
  String get orders => _value('orders');
  String get aiTools => _value('aiTools');
  String get myProducts => _value('myProducts');
  String get noScreensAvailable => _value('noScreensAvailable');

  String _value(String key) =>
      _translations[locale.languageCode]?[key] ?? _translations['ar']![key]!;

  static const _translations = <String, Map<String, String>>{
    'ar': {
      'defaultUser': 'مستخدم Tradex',
      'settings': 'الإعدادات',
      'editProfile': 'تعديل الملف الشخصي',
      'changePassword': 'تغيير كلمة المرور',
      'notifications': 'الإشعارات',
      'language': 'اللغة',
      'languageArabic': 'العربية',
      'languageEnglish': 'الإنجليزية',
      'favorites': 'المفضلة',
      'noFavorites': 'لا توجد منتجات مفضلة',
      'logout': 'تسجيل الخروج',
      'loggingOut': 'جارٍ تسجيل الخروج...',
      'passwordCurrent': 'كلمة المرور الحالية',
      'passwordNew': 'كلمة المرور الجديدة',
      'passwordConfirm': 'تأكيد كلمة المرور الجديدة',
      'passwordDescription': 'أنشئ كلمة مرور جديدة لحماية حسابك.',
      'showPassword': 'إظهار كلمة المرور',
      'hidePassword': 'إخفاء كلمة المرور',
      'passwordSave': 'حفظ كلمة المرور',
      'passwordCancel': 'إلغاء',
      'passwordChanged': 'تم تغيير كلمة المرور بنجاح',
      'passwordSuccessDescription':
          'تم تحديث كلمة المرور مع الحفاظ على جلستك الحالية.',
      'passwordBackToProfile': 'العودة إلى الملف الشخصي',
      'passwordRequired': 'هذا الحقل مطلوب.',
      'passwordMinLength': 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل.',
      'passwordMismatch': 'كلمتا المرور غير متطابقتين.',
      'sessionExpired': 'انتهت جلستك. يرجى تسجيل الدخول مجدداً.',
      'forbidden': 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
      'serverError': 'حدث خطأ في الخادم. حاول مجدداً.',
      'networkError': 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مجدداً.',
      'timeoutError': 'انتهت مهلة الطلب. حاول مجدداً.',
      'unexpectedError': 'حدث خطأ غير متوقع. حاول مجدداً.',
      'home': 'الرئيسية',
      'search': 'بحث',
      'categories': 'التصنيفات',
      'account': 'حسابي',
      'orders': 'الطلبات',
      'aiTools': 'أدوات AI',
      'myProducts': 'منتجاتي',
      'noScreensAvailable': 'لا توجد شاشات متاحة',
    },
    'en': {
      'defaultUser': 'Tradex user',
      'settings': 'Settings',
      'editProfile': 'Edit profile',
      'changePassword': 'Change password',
      'notifications': 'Notifications',
      'language': 'Language',
      'languageArabic': 'Arabic',
      'languageEnglish': 'English',
      'favorites': 'Favorites',
      'noFavorites': 'No favorite products',
      'logout': 'Log out',
      'loggingOut': 'Logging out...',
      'passwordCurrent': 'Current password',
      'passwordNew': 'New password',
      'passwordConfirm': 'Confirm new password',
      'passwordDescription':
          'Create a new password to keep your account secure.',
      'showPassword': 'Show password',
      'hidePassword': 'Hide password',
      'passwordSave': 'Save password',
      'passwordCancel': 'Cancel',
      'passwordChanged': 'Password changed successfully',
      'passwordSuccessDescription':
          'Your password was updated and your current session was kept active.',
      'passwordBackToProfile': 'Back to profile',
      'passwordRequired': 'This field is required.',
      'passwordMinLength': 'Password must be at least 6 characters.',
      'passwordMismatch': 'Passwords do not match.',
      'sessionExpired': 'Your session expired. Please sign in again.',
      'forbidden': 'You do not have permission to do this.',
      'serverError': 'A server error occurred. Please try again.',
      'networkError':
          'No internet connection. Check your network and try again.',
      'timeoutError': 'The request timed out. Please try again.',
      'unexpectedError': 'Something went wrong. Please try again.',
      'home': 'Home',
      'search': 'Search',
      'categories': 'Categories',
      'account': 'Account',
      'orders': 'Orders',
      'aiTools': 'AI tools',
      'myProducts': 'My products',
      'noScreensAvailable': 'No screens available',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'ar' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
