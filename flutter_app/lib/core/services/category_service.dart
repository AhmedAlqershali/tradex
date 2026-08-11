import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';

class CategoryOption {
  const CategoryOption({required this.id, required this.name});

  final String id;
  final String name;
}

// ─── CategoryService ──────────────────────────────────────────────────────────
//
// Handles the categories lookup endpoint.
//
// Endpoints:
//   GET /categories → paginated [{id, name}] records
//
// The legacy [getCities] method remains for unrelated screens that still
// compile against it; Home uses the device location service instead.
// ─────────────────────────────────────────────────────────────────────────────

class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  // ── Categories ────────────────────────────────────────────────────────────────
  /// GET /categories
  /// Returns category names while preserving the server IDs through
  /// [getCategoryOptions] for product filtering.
  Future<List<String>> getCategories() async {
    final options = await getCategoryOptions();
    return options.map((option) => option.name).toList();
  }

  Future<List<CategoryOption>> getCategoryOptions() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.categories);
    final raw = response.data!;
    return _extractOptions(raw);
  }

  // ── Cities ────────────────────────────────────────────────────────────────────
  /// Kept for existing callers; Home does not use this legacy path.
  Future<List<String>> getCities() async => const [];

  // ── Helpers ───────────────────────────────────────────────────────────────────

  List<CategoryOption> _extractOptions(Map<String, dynamic> raw) {
    final outer = raw['data'] ?? raw;
    final data =
        (outer is Map && outer['data'] is List) ? outer['data'] : outer;
    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map((item) {
          return CategoryOption(
            id: item['id'].toString(),
            name: (item['name'] ?? item['label'] ?? item['value'] ?? '')
                .toString(),
          );
        })
        .where((option) => option.name.isNotEmpty)
        .toList();
  }
}
