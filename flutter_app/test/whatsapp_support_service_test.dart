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
}
