import 'package:flutter/foundation.dart';
import 'package:ai_saas/shared/models/mock_order.dart';

// ─── Product line ─────────────────────────────────────────────────────────────

/// A single product within a placed order.
/// Built from [CartItem] at checkout time so the order snapshot is immutable
/// even after the cart is cleared.
///
/// All fields are JSON-serializable. The [id] field maps directly to the
/// server product ID.
class AppOrderProduct {
  final String id;
  final String name;
  final String storeName;
  final double price;
  final int quantity;

  /// Network image URL from the product listing. Null-safe — UI falls back to
  /// a generic icon when null or when the URL fails to load.
  final String? imageUrl;

  AppOrderProduct({
    required this.id,
    required this.name,
    required this.storeName,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  double get lineTotal => price * quantity;

  // ── JSON serialisation ───────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'storeName': storeName,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };

  factory AppOrderProduct.fromJson(Map<String, dynamic> json) =>
      AppOrderProduct(
        id: json['id'] as String,
        name: json['name'] as String,
        storeName: json['storeName'] as String? ?? '',
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toInt(),
        imageUrl: json['imageUrl'] as String?,
      );

  /// Constructs an [AppOrderProduct] from a server API response (snake_case).
  /// Server shape: { product_id, product_name (or name), price, quantity,
  ///                 image_url, store_name }
  factory AppOrderProduct.fromServerJson(Map<String, dynamic> json) =>
      AppOrderProduct(
        id: (json['product_id'] ?? json['id'])?.toString() ?? '',
        name: json['product_name'] as String? ?? json['name'] as String? ?? '',
        storeName: json['store_name'] as String? ??
            json['storeName'] as String? ??
            (json['store'] is Map
                ? json['store']['store_name'] as String? ?? ''
                : ''),
        price: json['price'] != null
            ? (json['price'] as num).toDouble()
            : json['unit_price'] != null
                ? (json['unit_price'] as num).toDouble()
                : 0.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      );
}

// ─── Order ────────────────────────────────────────────────────────────────────

/// A placed order created at checkout and shared between client and merchant.
///
/// [status] is the only mutable field — updated by the merchant via
/// [OrderController.updateOrderStatus]. All other fields are fixed at the
/// moment the order is placed.
///
/// [merchantId] is null until authentication is added. When a real auth layer
/// exists, populate this with the merchant's server ID so [OrderController]
/// can filter orders per merchant without changing any screen code.
class AppOrder {
  final String ref;
  final String? serverId;
  final DateTime createdAt;

  /// Reserved for per-merchant filtering. Null for client-placed orders
  /// (the backend associates orders with merchants via store ownership).
  final String? merchantId;

  /// Mutable — only [OrderController.updateOrderStatus] should write to this.
  OrderStatus status;

  final List<AppOrderProduct> products;
  final double? serverTotal;

  // ── Customer snapshot (captured from checkout form) ────────────────────────
  final String customerName;
  final String customerPhone;
  final String customerCity;
  final String? notes;

  AppOrder({
    required this.ref,
    this.serverId,
    required this.createdAt,
    required this.status,
    required this.products,
    this.serverTotal,
    required this.customerName,
    required this.customerPhone,
    required this.customerCity,
    this.merchantId,
    this.notes,
  });

  // ── Computed ───────────────────────────────────────────────────────────────

  double get total => serverTotal ??
      products.fold(0.0, (s, p) => s + p.lineTotal);
  int get itemCount => products.length;

  // ── JSON serialisation ─────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'ref': ref,
      'serverId': serverId,
        'createdAt': createdAt.toIso8601String(),
        'merchantId': merchantId,
        'status': _statusToString(status),
        'products': products.map((p) => p.toJson()).toList(),
        'totalAmount': serverTotal,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerCity': customerCity,
        'notes': notes,
      };

  factory AppOrder.fromJson(Map<String, dynamic> json) => AppOrder(
        ref: json['ref'] as String,
      serverId: json['serverId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        merchantId: json['merchantId'] as String?,
        status:
            _statusFromString(json['status'] as String? ?? 'pending_review'),
        serverTotal: (json['totalAmount'] as num?)?.toDouble(),
        products: (json['products'] as List<dynamic>)
            .map((e) => AppOrderProduct.fromJson(e as Map<String, dynamic>))
            .toList(),
        customerName: json['customerName'] as String,
        customerPhone: json['customerPhone'] as String,
        customerCity: json['customerCity'] as String,
        notes: json['notes'] as String?,
      );

  /// Constructs an [AppOrder] from a server API response (snake_case keys).
  /// Server shape:
  ///   { id, created_at, merchant_id, status, items (or products),
  ///     customer_name, customer_phone, customer_city, notes }
  factory AppOrder.fromServerJson(Map<String, dynamic> json) {
    // Keep both the client-facing public ref and the numeric server id used by
    // merchant detail routes. Some payloads expose the server id as `id` while
    // others use a public reference string in `ref`.
    final serverId = json['id']?.toString();
    final ref = json['ref'] as String? ?? serverId ?? '';

    // Items may be in `items` or `products` key.
    final rawItems = json['items'] ?? json['products'] ?? <dynamic>[];
    final storeName = json['store'] is Map
        ? json['store']['store_name'] as String? ?? ''
        : '';
    final products = <AppOrderProduct>[];
    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is! Map) continue;
        try {
          final item = Map<String, dynamic>.from(rawItem);
          if (storeName.isNotEmpty &&
              item['store_name'] == null &&
              item['storeName'] == null) {
            item['store_name'] = storeName;
          }
          products.add(AppOrderProduct.fromServerJson(item));
        } catch (_) {
          // Ignore one malformed item while preserving valid order items.
        }
      }
    }

    return AppOrder(
      ref: ref,
      serverId: serverId,
      createdAt: _parseDate(
        json['created_at'] as String? ?? json['createdAt'] as String?,
      ),
      merchantId:
          json['merchant_id'] as String? ?? json['merchantId'] as String?,
      status: _statusFromString(
        json['status'] as String? ?? 'pending_review',
      ),
      products: products,
      serverTotal: (json['total_amount'] as num?)?.toDouble() ??
          (json['totalAmount'] as num?)?.toDouble(),
      customerName: json['customer_name'] as String? ??
          json['customerName'] as String? ??
          '',
      customerPhone: json['customer_phone'] as String? ??
          json['customerPhone'] as String? ??
          '',
      customerCity: json['customer_city'] as String? ??
          json['customerCity'] as String? ??
          '',
      notes: json['notes'] as String?,
    );
  }

  static DateTime _parseDate(String? value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  static String _statusToString(OrderStatus s) {
    switch (s) {
      case OrderStatus.pendingReview:
        return 'pending_review';
      case OrderStatus.merchantContacted:
        return 'merchant_contacted';
      case OrderStatus.orderConfirmed:
        return 'order_confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static OrderStatus _statusFromString(String value) {
    switch (value) {
      case 'merchant_contacted':
        return OrderStatus.merchantContacted;
      case 'order_confirmed':
        return OrderStatus.orderConfirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pendingReview;
    }
  }

  /// Derived store name from the first product. When a proper merchant profile
  /// is linked, replace this with a dedicated [merchantStoreName] field.
  String get storeName => products.isNotEmpty ? products.first.storeName : '—';

  /// Arabic-formatted date string, e.g. "17 يوليو 2026".
  String get formattedDate {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

/// Singleton order controller — local cache layer for order state.
///
/// Follows the same [ValueNotifier] singleton pattern as [CartController].
/// Every [ValueListenableBuilder] subscribed to [ordersNotifier] rebuilds
/// automatically when an order is created or its status is updated.
///
/// The actual backend I/O is handled by [OrderBloc] → [OrderService]:
///   - POST /orders               → [OrderBloc] calls [createOrder] on success.
///   - GET  /orders               → [OrderBloc] calls [setOrders] on load.
///   - GET  /merchant/orders      → [OrderBloc] calls [setOrders] on load.
///   - PUT  /merchant/orders/:id/status → [OrderBloc] calls [updateOrderStatus].
///
/// [ordersNotifier] acts as the optimistic-update layer that keeps all
/// [ValueListenableBuilder] widgets in sync with server data.
class OrderController {
  OrderController._internal();
  static final OrderController instance = OrderController._internal();

  final ValueNotifier<List<AppOrder>> ordersNotifier =
      ValueNotifier<List<AppOrder>>([]);

  List<AppOrder> get orders => ordersNotifier.value;

  // ── Queries ────────────────────────────────────────────────────────────────

  /// All orders visible to the authenticated client.
  List<AppOrder> getClientOrders() => List.unmodifiable(orders);

  /// All orders visible to the authenticated merchant.
  List<AppOrder> getMerchantOrders() => List.unmodifiable(orders);

  /// Orders currently awaiting merchant review.
  List<AppOrder> getPendingOrders() =>
      orders.where((o) => o.status == OrderStatus.pendingReview).toList();

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Replaces the entire order list after a backend sync.
  /// Called by [OrderBloc] after a successful load so that all
  /// [ValueListenableBuilder] widgets (e.g. [ClientOrderDetailsScreen]) stay
  /// in sync with server data.
  void setOrders(List<AppOrder> serverOrders) {
    ordersNotifier.value = List<AppOrder>.from(serverOrders);
  }

  /// Adds a new order at the front of the list (most-recent-first ordering).
  void createOrder(AppOrder order) {
    ordersNotifier.value = [order, ...orders];
  }

  /// Updates the [status] of the order identified by server [id] and notifies all
  /// listeners. Uses a list copy so [ValueListenableBuilder] detects the change.
  void updateOrderStatus(String id, OrderStatus newStatus) {
    final list = List<AppOrder>.from(orders);
    final index = list.indexWhere((o) => o.serverId == id);
    if (index < 0) return;
    list[index].status = newStatus;
    ordersNotifier.value = List<AppOrder>.from(list);
  }

  // ── Status parsing ────────────────────────────────────────────────────────

  /// Converts a server status string into an [OrderStatus] enum value.
  /// Used by [OrderBloc] when patching a single order status.
  static OrderStatus parseStatus(String value) {
    switch (value) {
      case 'merchant_contacted':
        return OrderStatus.merchantContacted;
      case 'order_confirmed':
        return OrderStatus.orderConfirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pendingReview;
    }
  }
}

// ─── Ref generator ────────────────────────────────────────────────────────────

/// Generates a fallback order reference for cases where the server returns
/// an order with an empty ref (e.g. partial response). The server-assigned
/// ref is always preferred — see [OrderBloc._onOrderCreateRequested].
/// Format: TRX-YYYYMMDD-XXXX
String generateOrderRef() {
  final now = DateTime.now();
  final date =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final suffix = (1000 + now.millisecondsSinceEpoch % 9000).toString();
  return 'TRX-$date-$suffix';
}
