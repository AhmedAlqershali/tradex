import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/product_model.dart';

// ─── FavoriteService ──────────────────────────────────────────────────────────
//
// Handles authenticated customer favorites.
//
// Endpoints:
//   GET    /favorites
//   POST   /favorites           { product_id }
//   DELETE /favorites/:productId
// ─────────────────────────────────────────────────────────────────────────────

class FavoriteService {
  FavoriteService._();
  static final FavoriteService instance = FavoriteService._();

  /// GET /favorites
  /// Returns the full product details for all products the user has favorited.
  Future<List<Product>> getFavorites() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.favorites);
    final raw = response.data!;
    final data = raw['data'] ?? raw;
    if (data is List) {
      return data
          .cast<Map<String, dynamic>>()
          .map((e) {
            // Server may return { product: {...} } wrappers or plain product objects.
            final productJson =
                e['product'] is Map ? e['product'] as Map<String, dynamic> : e;
            return Product.fromServerJson(productJson);
          })
          .toList();
    }
    return [];
  }

  /// POST /favorites
  Future<void> addFavorite(String productId) async {
    await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.favorites,
      data: {'product_id': productId},
    );
  }

  /// DELETE /favorites/:productId
  Future<void> removeFavorite(String productId) async {
    await ApiClient.instance
        .delete<Map<String, dynamic>>(ApiConstants.favoriteById(productId));
  }
}
