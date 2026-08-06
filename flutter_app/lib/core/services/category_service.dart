import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';

// ─── CategoryService ──────────────────────────────────────────────────────────
//
// Handles the categories lookup endpoint.
//
// Endpoints:
//   GET /categories → paginated List<String>
//
// Note: the backend has no cities/regions endpoint at all — city selection
// in the app (checkout, profile screens) already uses a static hardcoded
// list rather than an API call, so [getCities] below is kept only for
// forward-compatibility if the backend adds one later; it currently returns
// an empty list rather than hitting a route that doesn't exist.
// ─────────────────────────────────────────────────────────────────────────────

class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  // ── Categories ────────────────────────────────────────────────────────────────
  /// GET /categories
  /// Returns the list of product/store category strings defined on the backend.
  Future<List<String>> getCategories() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.categories);
    final raw = response.data!;
    return _extractStringList(raw);
  }

  // ── Cities ────────────────────────────────────────────────────────────────────
  /// The backend has no cities/regions endpoint — always returns an empty
  /// list. Kept so [CategoryBloc]'s existing CitiesRequested handler (which
  /// nothing currently listens to) doesn't need to change.
  Future<List<String>> getCities() async => const [];

  // ── Helpers ───────────────────────────────────────────────────────────────────

  List<String> _extractStringList(Map<String, dynamic> raw) {
    // Backend wraps paginated collections as { data: { data: [...], links,
    // meta } } — unwrap one extra level when present.
    final outer = raw['data'] ?? raw;
    final data = (outer is Map && outer['data'] is List) ? outer['data'] : outer;
    if (data is List) {
      return data.map((e) {
        if (e is String) return e;
        // Server may return [{ "id": ..., "name": "..." }] objects.
        if (e is Map) {
          return (e['name'] ?? e['label'] ?? e['value'] ?? '').toString();
        }
        return e.toString();
      }).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
}
