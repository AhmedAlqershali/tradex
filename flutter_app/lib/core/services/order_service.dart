// cancelled) matches the app's four persisted order states
// (pending_review/order_confirmed/completed/cancelled). Contact is an
// interaction and is not serialized as an order status.
import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';

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
// The backend's order-status enum is the persisted source of truth. The client
// only translates the confirmed UI enum name to the backend's `confirmed`
// value; contact remains an interaction rather than a persisted state.
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
        .map((item) => AppOrder.fromServerJson(Map<String, dynamic>.from(item)))
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
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
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
    return AppOrder.fromServerJson(orderJson);
  }

  // ── Status update (merchant only) ─────────────────────────────────────────────
  /// PUT /merchant/orders/:id/status
  /// [status] is one of the merchant transition statuses (confirmed,
  /// completed, or cancelled).
  Future<AppOrder> patchStatus({
    required String id,
    required String status,
  }) async {
    if (id.isEmpty || int.tryParse(id) == null) {
      throw const ValidationException('معرف الطلب غير صالح.');
    }
    final endpoint = ApiConstants.merchantOrderStatus(id);
    final payload = {'status': _toBackendStatus(status)};
    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      endpoint,
      data: payload,
    );
    final raw = response.data!;
    final orderJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return AppOrder.fromServerJson(orderJson);
  }

  // ── Status vocabulary translation ─────────────────────────────────────────────

  /// App UI status → backend enum. Unknown statuses fail instead of being
  /// silently converted into a pending order.
  static String _toBackendStatus(String appStatus) {
    switch (appStatus) {
      case 'order_confirmed':
      case 'orderConfirmed':
      case 'confirmed':
        return 'confirmed';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        throw FormatException('Unknown merchant order status: $appStatus');
    }
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
          .map(AppOrder.fromServerJson)
          .toList();
    }
    return [];
  }
}
