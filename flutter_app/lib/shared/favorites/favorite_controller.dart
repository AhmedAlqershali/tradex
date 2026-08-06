import 'package:flutter/foundation.dart';
import 'package:ai_saas/shared/models/product_model.dart';

/// Singleton favorites controller.
///
/// Follows the same [ValueNotifier] singleton pattern as [ProductController].
/// All [ValueListenableBuilder] widgets subscribed to [favoritesNotifier]
/// rebuild automatically when the favorites list changes.
///
/// Migration path to a real backend:
///   - [addFavorite]    → POST   /favorites
///   - [removeFavorite] → DELETE /favorites/{productId}
///   - [getFavorites]   → GET    /favorites?userId={id}
class FavoriteController {
  FavoriteController._internal();
  static final FavoriteController instance = FavoriteController._internal();

  /// Reactive favorites list. Listen with [ValueListenableBuilder].
  final ValueNotifier<List<Product>> favoritesNotifier =
      ValueNotifier<List<Product>>([]);

  List<Product> get favorites => favoritesNotifier.value;

  int get count => favorites.length;

  // ── Queries ──────────────────────────────────────────────────────────────────

  bool isFavorite(String productId) =>
      favorites.any((p) => p.id == productId);

  List<Product> getFavorites() => List.unmodifiable(favorites);

  // ── Mutations ─────────────────────────────────────────────────────────────────

  /// Adds [product] to favorites if not already present.
  void addFavorite(Product product) {
    if (!isFavorite(product.id)) {
      favoritesNotifier.value = [product, ...favorites];
    }
  }

  /// Removes the product identified by [productId] from favorites.
  void removeFavorite(String productId) {
    favoritesNotifier.value =
        favorites.where((p) => p.id != productId).toList();
  }

  /// Adds if not favorited, removes if already favorited.
  void toggleFavorite(Product product) {
    if (isFavorite(product.id)) {
      removeFavorite(product.id);
    } else {
      addFavorite(product);
    }
  }

  /// Clears all favorites — called on logout.
  void clear() {
    favoritesNotifier.value = [];
  }
}
