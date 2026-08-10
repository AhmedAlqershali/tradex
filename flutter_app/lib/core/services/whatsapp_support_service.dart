import 'whatsapp_support_launcher_stub.dart'
    if (dart.library.html) 'whatsapp_support_launcher_web.dart' as launcher;

/// External WhatsApp support handoff used by the subscription renewal flow.
///
/// This only opens a chat. It does not submit a subscription request, record
/// payment, or change subscription state.
class WhatsAppSupportService {
  WhatsAppSupportService._();

  static const supportPhoneNumber = '+972597668446';
  static const _waPhoneNumber = '972597668446';

  static Uri get chatUri => Uri.parse('https://wa.me/$_waPhoneNumber');

  static Future<bool> openChat() =>
      launcher.openWhatsAppChat(chatUri.toString());
}
