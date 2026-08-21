import 'package:flutter_test/flutter_test.dart';

import 'package:ai_saas/core/services/whatsapp_support_service.dart';

void main() {
  test('uses the configured WhatsApp support number and chat URL', () {
    expect(
      WhatsAppSupportService.supportPhoneNumber,
      '+972597668446',
    );
    expect(
      WhatsAppSupportService.chatUri.toString(),
      'https://wa.me/972597668446',
    );
  });

  test('normalizes local, international, and formatted customer phones', () {
    expect(WhatsAppSupportService.normalizePhone('059 123 4567'), '972591234567');
    expect(WhatsAppSupportService.normalizePhone('+972 59 123 4567'), '972591234567');
    expect(WhatsAppSupportService.normalizePhone('0059 123 4567'), '591234567');
    expect(WhatsAppSupportService.normalizePhone(''), isNull);
  });
}
