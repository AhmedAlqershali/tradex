  /// cancelled) is coarser than the app's 6-value UI vocabulary
  /// (pending_review/merchant_contacted/order_confirmed/preparing/completed/
  /// cancelled) — [_toBackendStatus]/[_fromBackendStatus] translate at this boundary.
import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';
import 'package:flutter/foundation.dart';

// ─── OrderService ─────────────────────────────────────────────────────────────
//
// Handles order submission and status management.
//
// Endpoints:
//   POST /orders                        (client — create)
//   GET  /orders                        (client — own orders)
//   GET  /orders/:id                    (client — own order detail)
//   GET  /merchant/orders               (merchant — store's orders)
//   GET  /merchant/orders/:id           (merchant — order detail)
//   PUT  /merchant/orders/:id/status    { status }  (merchant only)
//
// The backend's order-status enum (pending/contacted/confirmed/processing/completed/
// cancelled) is coarser than the app's 6-value UI vocabulary
// (pending_review/merchant_contacted/order_confirmed/preparing/completed/
// cancelled) — [_toBackendStatus]/[_fromBackendStatus] translate at this
// boundary so OrderController/OrderBloc/the screens don't need to change.
// ─────────────────────────────────────────────────────────────────────────────

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  // ── Submit order ──────────────────────────────────────────────────────────────
  /// POST /orders
  /// The backend reads the authenticated user's server cart and creates one
  /// order per store. Returns every server-created order.
  Future<List<AppOrder>> createOrder({
    required String customerName,
    required String customerPhone,
    required String customerCity,
    String? notes,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.orders,
      data: {
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_city': customerCity,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    final raw = response.data!;
    final data = raw['data'] ?? raw;
    final list = data is List
        ? data
        : data is Map && data['data'] is List
            ? data['data'] as List
            : data is Map
                ? [data]
                : const [];
    return list
        .whereType<Map>()
        .map((item) => AppOrder.fromServerJson(
              _normaliseStatus(Map<String, dynamic>.from(item)),
            ))
        .toList();
  }

  // ── Fetch orders ──────────────────────────────────────────────────────────────
  /// GET /orders — all orders belonging to the authenticated client.
  Future<List<AppOrder>> getClientOrders() async {
    final response =
        await ApiClient.instance.get<Map<String, dynamic>>(ApiConstants.orders);
    final raw = response.data!;
    return _extractOrderList(raw);
  }

  /// GET /merchant/orders — all orders for the authenticated merchant's store.
  Future<List<AppOrder>> getMerchantOrders({String? status}) async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(
          ApiConstants.merchantOrders,
          queryParameters: {
            if (status != null && status.isNotEmpty) 'status': status,
          },
        );
    final raw = response.data!;
    return _extractOrderList(raw);
  }

  /// GET /orders/:id or GET /merchant/orders/:id depending on [asMerchant].
  /// The two roles hit different route namespaces on this backend — there is
  /// no single generic "order by ref" endpoint usable by both.
  Future<AppOrder> getOrderById(String id, {bool asMerchant = true}) async {
    final path = asMerchant
        ? ApiConstants.merchantOrderById(id)
        : ApiConstants.orderById(id);
    final response = await ApiClient.instance.get<Map<String, dynamic>>(path);
    final raw = response.data!;
    final orderJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return AppOrder.fromServerJson(_normaliseStatus(orderJson));
  }

  // ── Status update (merchant only) ─────────────────────────────────────────────
  /// PUT /merchant/orders/:id/status
  /// [status] is one of the app's UI-vocabulary strings (pending_review,
  /// merchant_contacted, order_confirmed, preparing, completed, cancelled) —
  /// translated to the backend's enum before sending.
  Future<AppOrder> patchStatus({
    required String id,
    required String status,
  }) async {
    final endpoint = ApiConstants.merchantOrderStatus(id);
    final payload = {'status': _toBackendStatus(status)};
    debugPrint('[OrderService] PUT $endpoint serverId=$id '
        'targetStatus=${payload['status']} payload=$payload');
    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      endpoint,
      data: payload,
    );
    debugPrint('[OrderService] response status=${response.statusCode} '
        'body=${response.data}');
    final raw = response.data!;
    final orderJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return AppOrder.fromServerJson(_normaliseStatus(orderJson));
  }

  // ── Status vocabulary translation ─────────────────────────────────────────────

  /// App UI status → backend enum. The backend recognises pending, contacted,
  /// confirmed, processing, completed, and cancelled.
  static String _toBackendStatus(String appStatus) {
    switch (appStatus) {
      case 'merchant_contacted':
      case 'merchantContacted':
      case 'contacted':
        return 'contacted';
      case 'order_confirmed':
      case 'orderConfirmed':
      case 'confirmed':
        return 'confirmed';
      case 'preparing':
      case 'processing':
        return 'processing';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      case 'pending_review':
      default:
        return 'pending';
    }
  }

  /// Backend enum → app UI status, for order JSON coming back from the
  /// server (list/detail responses).
  static String _fromBackendStatus(String backendStatus) {
    switch (backendStatus) {
      case 'pending':
        return 'pending_review';
      case 'contacted':
        return 'merchant_contacted';
      case 'confirmed':
        return 'order_confirmed';
      case 'processing':
        return 'preparing';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'pending_review';
    }
  }

  Map<String, dynamic> _normaliseStatus(Map<String, dynamic> orderJson) {
    final status = orderJson['status'];
    if (status is String) {
      return {...orderJson, 'status': _fromBackendStatus(status)};
    }
    return orderJson;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  List<AppOrder> _extractOrderList(Map<String, dynamic> raw) {
    final data = raw['data'] ?? raw;
    final list = data is Map && data['data'] is List
        ? data['data']
        : data is Map && data['id'] != null
            ? [data]
            : data;
    if (list is List) {
      return list
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_normaliseStatus)
          .map(AppOrder.fromServerJson)
          .toList();
    }
    return [];
  }
}
