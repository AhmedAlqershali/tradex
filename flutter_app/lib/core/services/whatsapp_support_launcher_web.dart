// The web adapter intentionally uses the browser API directly so this feature
// does not add a package or alter the existing dependency set.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<bool> openWhatsAppChat(String url) {
  html.window.open(url, '_blank');
  return Future.value(true);
}
