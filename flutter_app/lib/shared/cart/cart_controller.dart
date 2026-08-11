import 'package:flutter/foundation.dart';

/// Represents a single line item in the shopping cart.
///
/// Designed to map 1-to-1 with a server cart item.
/// [id] is the product ID (used for UI matching and add-to-cart deduplication).
/// [serverItemId] is the cart-row ID assigned by the server, required for
/// PUT /cart/items/:itemId and DELETE /cart/items/:itemId operations.
class CartItem {
  /// Product identifier — matches [Product.id].
  final String id;
  final String name;
  final String storeName;
  final double price;

  /// Optional network image URL. Falls back to a generic icon when null.
  final String? imageUrl;

  /// Server-assigned cart-item row ID.
  /// Null until the item has been synced with the backend via [CartService].
  /// Use this value for update/remove API calls.
  final String? serverItemId;

  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.storeName,
    required this.price,
    this.imageUrl,
    this.serverItemId,
    this.quantity = 1,
  });

  double get lineTotal => price * quantity;

  CartItem copyWith({int? quantity, String? serverItemId}) => CartItem(
        id: id,
        name: name,
        storeName: storeName,
        price: price,
        imageUrl: imageUrl,
        serverItemId: serverItemId ?? this.serverItemId,
        quantity: quantity ?? this.quantity,
      );

  // ── JSON serialisation (local persistence) ────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'storeName': storeName,
        'price': price,
        'imageUrl': imageUrl,
        'serverItemId': serverItemId,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        name: json['name'] as String,
        storeName: json['storeName'] as String,
        price: (json['price'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String?,
        serverItemId: json['serverItemId'] as String?,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );

  /// Constructs a [CartItem] from a server API cart-item response.
  /// Server shape:
  ///   { id, product_id, name (or product_name), price, quantity,
  ///     image_url, store_name }
  factory CartItem.fromServerJson(Map<String, dynamic> json) {
    // The server item id is the cart row id; product id is a separate field.
    final serverItemId = json['id']?.toString();
    final productMap = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : null;
    final productId =
        (json['product_id'] ?? json['productId'] ?? productMap?['id'])
                ?.toString() ??
            serverItemId ??
            '';

    // Product name may come as `name`, `product_name`, or inside a nested product.
    final name = json['name'] as String? ??
        json['product_name'] as String? ??
        productMap?['name'] as String? ??
        '';

    final nestedStore = productMap?['store'];
    final storeName = json['store_name'] as String? ??
        json['storeName'] as String? ??
        productMap?['store_name'] as String? ??
        productMap?['storeName'] as String? ??
        (nestedStore is Map
            ? (nestedStore['store_name'] ?? nestedStore['name']) as String?
            : '') ??
        '';

    final imageUrl = json['image_url'] as String? ??
        json['imageUrl'] as String? ??
        productMap?['image'] as String? ??
        productMap?['image_url'] as String?;

    final price = json['price'] != null
        ? (json['price'] as num).toDouble()
        : json['unit_price'] != null
            ? (json['unit_price'] as num).toDouble()
            : productMap?['price'] != null
                ? (productMap!['price'] as num).toDouble()
                : 0.0;

    final quantity = (json['quantity'] as num?)?.toInt() ?? 1;

    return CartItem(
      id: productId,
      name: name,
      storeName: storeName,
      price: price,
      imageUrl: imageUrl,
      serverItemId: serverItemId,
      quantity: quantity,
    );
  }
}

/// Singleton cart controller.
///
/// Exposes a [ValueNotifier] so [ValueListenableBuilder] widgets rebuild
/// automatically without any external state-management package.
///
/// Migration path to a real backend:
///   - Replace each mutation method body with an API call.
///   - Keep [itemsNotifier] as the local cache / optimistic-update layer.
///   - Add an `isLoading` / `error` notifier alongside when needed.
class CartController {
  CartController._internal();

  static final CartController instance = CartController._internal();

  /// The reactive cart list. Listen with [ValueListenableBuilder].
  final ValueNotifier<List<CartItem>> itemsNotifier =
      ValueNotifier<List<CartItem>>([]);

  // ── Convenience getters ─────────────────────────────────────────────────────

  List<CartItem> get items => itemsNotifier.value;

  double get total => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  // ── Mutations ───────────────────────────────────────────────────────────────

  /// Adds [item] to the cart.
  /// If the product already exists (matched by [CartItem.id]), its quantity
  /// is incremented rather than creating a duplicate entry.
  void addItem(CartItem item) {
    final list = List<CartItem>.from(items);
    final index = list.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      list[index] = list[index].copyWith(
        quantity: list[index].quantity + item.quantity,
      );
    } else {
      list.add(item);
    }
    itemsNotifier.value = list;
  }

  void increment(String id) {
    final list = List<CartItem>.from(items);
    final index = list.indexWhere((e) => e.id == id);
    if (index < 0) return;
    list[index] = list[index].copyWith(quantity: list[index].quantity + 1);
    itemsNotifier.value = list;
  }

  void decrement(String id) {
    final list = List<CartItem>.from(items);
    final index = list.indexWhere((e) => e.id == id);
    if (index < 0) return;
    if (list[index].quantity > 1) {
      list[index] = list[index].copyWith(quantity: list[index].quantity - 1);
    } else {
      list.removeAt(index);
    }
    itemsNotifier.value = list;
  }

  void remove(String id) {
    itemsNotifier.value = List<CartItem>.from(items)
      ..removeWhere((e) => e.id == id);
  }

  /// Replaces the entire cart with [items] fetched from the server.
  /// Call this after a successful [CartService.getCart] response so the
  /// controller's in-memory list stays in sync with backend data.
  void setItems(List<CartItem> items) {
    itemsNotifier.value = List<CartItem>.from(items);
  }

  /// Empties the cart — call this after an order is confirmed.
  void clear() {
    itemsNotifier.value = [];
  }
}
