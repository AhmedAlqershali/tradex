import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/services/product_service.dart';
import 'package:ai_saas/core/services/order_service.dart';
import 'package:ai_saas/core/services/store_service.dart';
import 'package:ai_saas/screens/client/client_order_details_screen.dart';
import 'package:ai_saas/screens/merchant/merchant_order_details_screen.dart';
import 'package:ai_saas/screens/product_details_screen.dart';
import 'package:ai_saas/screens/store_details_screen.dart';
import 'package:ai_saas/shared/users/user_controller.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<String>? _tokenSubscription;
  bool _ready = false;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await _register(await messaging.getToken());
      _tokenSubscription = messaging.onTokenRefresh.listen(_register);
      FirebaseMessaging.onMessageOpenedApp.listen(_open);
      final initial = await messaging.getInitialMessage();
      if (initial != null) unawaited(_open(initial));
      _ready = true;
      UserController.instance.currentUserNotifier.addListener(_userChanged);
    } catch (_) {
      // Platform Firebase configuration is supplied outside the repository.
    }
  }

  void _userChanged() {
    if (_ready) unawaited(FirebaseMessaging.instance.getToken().then(_register));
  }

  Future<void> _register(String? token) async {
    if (token == null || token.isEmpty || UserController.instance.currentUser == null) return;
    try {
      await ApiClient.instance.post<Map<String, dynamic>>(
        ApiConstants.deviceTokens,
        data: {'token': token, 'platform': 'android'},
      );
    } catch (_) {}
  }

  Future<void> _open(RemoteMessage message) async {
    await openData(message.data);
  }

  Future<void> openData(Map<String, dynamic> data) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    try {
      if (data['product_id'] != null) {
        final product = await ProductService.instance.getProductById('${data['product_id']}');
        navigator.push(MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)));
      } else if (data['order_id'] != null) {
        final orderId = '${data['order_id']}';
        final isMerchant = UserController.instance.currentUser?.role.name == 'merchant';
        if (isMerchant) {
          navigator.push(MaterialPageRoute(builder: (_) => MerchantOrderDetailsScreen(orderId: orderId)));
        } else {
          final order = await OrderService.instance.getOrderById(orderId, asMerchant: false);
          navigator.push(MaterialPageRoute(builder: (_) => ClientOrderDetailsScreen(order: order)));
        }
      } else if (data['store_id'] != null) {
        final store = await StoreService.instance.getStoreById('${data['store_id']}');
        navigator.push(MaterialPageRoute(builder: (_) => StoreDetailsScreen(store: store)));
      }
    } catch (_) {}
  }
}