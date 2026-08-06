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
  Future<List<CartItem>> getCart() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.cart);
    final raw = response.data!;
    return _extractCartItems(raw);
  }

  /// POST /cart/items
  /// Adds a product to the server cart. Returns the updated cart item.
  Future<CartItem> addItem({
    required String productId,
    required int quantity,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.cartItems,
      data: {'product_id': productId, 'quantity': quantity},
    );
    final raw = response.data!;
    final itemJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return CartItem.fromServerJson(itemJson);
  }

  /// PUT /cart/items/:itemId
  /// Updates the quantity of an existing cart item on the server.
  Future<CartItem> updateItem({
    required String itemId,
    required int quantity,
  }) async {
    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      ApiConstants.cartItem(itemId),
      data: {'quantity': quantity},
    );
    final raw = response.data!;
    final itemJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return CartItem.fromServerJson(itemJson);
  }

  /// DELETE /cart/items/:itemId
  Future<void> removeItem(String itemId) async {
    await ApiClient.instance
        .delete<Map<String, dynamic>>(ApiConstants.cartItem(itemId));
  }

  /// DELETE /cart
  /// Clears all items from the server-side cart.
  Future<void> clearCart() async {
    await ApiClient.instance
        .delete<Map<String, dynamic>>(ApiConstants.cart);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  List<CartItem> _extractCartItems(Map<String, dynamic> raw) {
    // Server may return { data: { items: [...] } } or { data: [...] }.
    final data = raw['data'];
    List<dynamic> list = [];

    if (data is Map && data['items'] is List) {
      list = data['items'] as List;
    } else if (data is List) {
      list = data;
    }

    return list
        .cast<Map<String, dynamic>>()
        .map(CartItem.fromServerJson)
        .toList();
  }
}
