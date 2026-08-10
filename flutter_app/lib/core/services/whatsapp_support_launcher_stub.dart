import 'package:flutter/services.dart';

const _channel = MethodChannel('ps.tradex.app/whatsapp_support');

Future<bool> openWhatsAppChat(String url) async {
  try {
    return await _channel.invokeMethod<bool>('open', {'url': url}) ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
