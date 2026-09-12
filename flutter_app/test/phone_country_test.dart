import 'package:ai_saas/core/utils/phone_country.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneCountry', () {
    test('detects explicit country code from stored numbers', () {
      expect(PhoneCountry.detectFromPhone('+970599123456'), '+970');
      expect(PhoneCountry.detectFromPhone('+972599123456'), '+972');
      expect(PhoneCountry.detectFromPhone('00972599123456'), '+972');
    });

    test('falls back to the default code for local numbers', () {
      expect(PhoneCountry.detectFromPhone('0591234567'), '+970');
      expect(PhoneCountry.detectFromPhone('599123456'), '+970');
    });

    test('applies the user-selected country code consistently', () {
      expect(PhoneCountry.applyCountryCode('0591234567', '+970'), '+970591234567');
      expect(PhoneCountry.applyCountryCode('0591234567', '+972'), '+972591234567');
      expect(PhoneCountry.applyCountryCode('+970591234567', '+972'), '+972591234567');
      expect(PhoneCountry.applyCountryCode('+972591234567', '+970'), '+970591234567');
    });
  });
}
