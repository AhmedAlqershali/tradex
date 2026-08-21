import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

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
    expect(WhatsAppSupportService.normalizePhone('056-123-4567'), '972561234567');
    expect(WhatsAppSupportService.normalizePhone('+972 59 123 4567'), '972591234567');
    expect(WhatsAppSupportService.normalizePhone('00972 59 123 4567'), '972591234567');
    expect(WhatsAppSupportService.normalizePhone(''), isNull);
    expect(WhatsAppSupportService.normalizePhone('12345678'), isNull);
  });

  test('opens a customer chat without changing order status', () async {
    final channel = const MethodChannel('ps.tradex.app/whatsapp_support');
    String? openedUrl;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      openedUrl = (call.arguments as Map)['url'] as String;
      return true;
    });

    final opened = await WhatsAppSupportService.openCustomerChat('0591234567');

    expect(opened, isTrue);
    expect(openedUrl, 'https://wa.me/972591234567');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reports a failed customer chat launch', () async {
    final channel = const MethodChannel('ps.tradex.app/whatsapp_support');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => false);

    expect(
      await WhatsAppSupportService.openCustomerChat('0561234567'),
      isFalse,
    );
    expect(await WhatsAppSupportService.openCustomerChat('invalid'), isFalse);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
