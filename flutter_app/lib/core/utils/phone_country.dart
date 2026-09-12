class PhoneCountry {
  static const List<String> supportedCountryCodes = ['+970', '+972'];
  static const String defaultCountryCode = '+970';

  static String detectFromPhone(String? value) {
    final digits = _digitsOnly(value ?? '');
    if (digits.isEmpty) return defaultCountryCode;

    final normalized = digits.startsWith('00') ? digits.substring(2) : digits;
    if (normalized.startsWith('972')) return '+972';
    if (normalized.startsWith('970')) return '+970';
    if (normalized.startsWith('5')) return defaultCountryCode;

    return defaultCountryCode;
  }

  static String stripCountryCode(String? value) {
    final digits = _digitsOnly(value ?? '');
    if (digits.isEmpty) return '';

    final normalized = digits.startsWith('00') ? digits.substring(2) : digits;
    if (normalized.startsWith('972')) {
      return normalized.substring(3);
    }
    if (normalized.startsWith('970')) {
      return normalized.substring(3);
    }
    if (normalized.startsWith('0')) {
      return normalized.substring(1);
    }

    return normalized;
  }

  static String applyCountryCode(String? value, String countryCode) {
    final normalizedCode = supportedCountryCodes.contains(countryCode)
        ? countryCode
        : defaultCountryCode;
    final localNumber = stripCountryCode(value ?? '');
    if (localNumber.isEmpty) return normalizedCode;
    final cleaned = localNumber.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return normalizedCode;
    return '$normalizedCode$cleaned';
  }

  static String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');
}
