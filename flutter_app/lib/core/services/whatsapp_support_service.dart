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

    static Future<bool> openCustomerChat(String phone) async {
        final normalized = normalizePhone(phone);
        if (normalized == null) return false;
        return launcher.openWhatsAppChat('https://wa.me/$normalized');
    }

    static String? normalizePhone(String value) {
        var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.startsWith('00')) digits = digits.substring(2);
        if (digits.startsWith('05')) {
            if (digits.length != 10) return null;
            return '972${digits.substring(1)}';
        }
        if (digits.startsWith('972')) {
            if (digits.length != 12 ||
                    !(digits.startsWith('9725') || digits.startsWith('9726'))) {
                return null;
            }
            return digits;
    }
        return null;

  static Future<bool> openChat() =>
      launcher.openWhatsAppChat(chatUri.toString());
}
