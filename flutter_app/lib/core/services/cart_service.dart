import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/cart/cart_controller.dart';

// ─── CartService ──────────────────────────────────────────────────────────────
//
// Handles server-synced cart operations.
//
// Endpoints:
//   GET    /cart
//   POST   /cart/items          { product_id, quantity }
//   PUT    /cart/items/:itemId  { quantity }
//   DELETE /cart/items/:itemId
//   DELETE /cart
// ─────────────────────────────────────────────────────────────────────────────

class CartService {
  CartService._();
  static final CartService instance = CartService._();

  /// GET /cart
  /// Returns the current user's cart items from the server.
  Future<CartResponse> getCart() async {
    final response =
        await ApiClient.instance.get<Map<String, dynamic>>(ApiConstants.cart);
    final raw = response.data!;
    return _extractCartItems(raw);
  }

  /// POST /cart/items
  /// Adds a product to the server cart. Returns the updated cart items.
  Future<CartResponse> addItem({
    required String productId,
    required int quantity,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.cartItems,
      data: {'product_id': productId, 'quantity': quantity},
    );
    final raw = response.data!;
    return _extractCartItems(raw);
  }

  /// PUT /cart/items/:itemId
  /// Updates the quantity of an existing cart item on the server.
  Future<CartResponse> updateItem({
    required String itemId,
    required int quantity,
  }) async {
    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      ApiConstants.cartItem(itemId),
      data: {'quantity': quantity},
    );
    final raw = response.data!;
    return _extractCartItems(raw);
  }

  /// DELETE /cart/items/:itemId. Returns the authoritative cart response.
  Future<CartResponse> removeItem(String itemId) async {
    final response = await ApiClient.instance
        .delete<Map<String, dynamic>>(ApiConstants.cartItem(itemId));
    return _extractCartItems(response.data!);
  }

  /// DELETE /cart. Returns the authoritative empty cart response.
  Future<CartResponse> clearCart() async {
    final response = await ApiClient.instance
        .delete<Map<String, dynamic>>(ApiConstants.cart);
    return _extractCartItems(response.data!);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  CartResponse _extractCartItems(Map<String, dynamic> raw) {
    // Server may return { data: { items: [...] } } or { data: [...] }.
    final data = raw['data'];
    List<dynamic> list = [];

    if (data is Map && data['items'] is List) {
      list = data['items'] as List;
    } else if (data is List) {
      list = data;
    }

    final items = <CartItem>[];
    for (final item in list) {
      if (item is! Map) continue;
      try {
        items.add(CartItem.fromServerJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        // Ignore one malformed item while preserving valid entries.
      }
    }

    final metadata = data is Map ? data : const <String, dynamic>{};
    return CartResponse(
      items: items,
      itemCount: (metadata['item_count'] as num?)?.toInt(),
      subtotal: (metadata['subtotal'] as num?)?.toDouble(),
    );
  }
}

class CartResponse {
  const CartResponse({required this.items, this.itemCount, this.subtotal});

  final List<CartItem> items;
  final int? itemCount;
  final double? subtotal;
}
