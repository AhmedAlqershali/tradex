import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/api/app_config.dart';

class CategoryOption {
  const CategoryOption({required this.id, required this.name, this.imageUrl});

  final String id;
  final String name;
  final String? imageUrl;

  factory CategoryOption.fromServerJson(Map<String, dynamic> json) {
    final rawImage = json['image'];

    return CategoryOption(
      id: json['id'].toString(),
      name: (json['name'] ?? json['label'] ?? json['value'] ?? '').toString(),
      imageUrl: rawImage is String && rawImage.trim().isNotEmpty
          ? AppConfig.resolveMediaUrl(rawImage)
          : null,
    );
  }
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
    const perPage = 100;
    final pages = <Map<String, dynamic>>[];
    int page = 1;
    int lastPage = 1;

    while (page <= lastPage) {
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        ApiConstants.categories,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      final raw = response.data ?? const {};
      if (raw is! Map<String, dynamic>) {
        break;
      }

      pages.add(raw);

      final pageOptions = _extractOptions(raw);
      if (pageOptions.isEmpty && page > 1) {
        break;
      }

      final pagination = raw['pagination'];
      if (pagination is! Map) {
        break;
      }

      final nextLastPage = pagination['last_page'];
      lastPage = nextLastPage is int ? nextLastPage : 1;
      if (page >= lastPage) break;
      page += 1;
    }

    return mergePaginatedResponses(pages);
  }

  static List<CategoryOption> mergePaginatedResponses(
    List<Map<String, dynamic>> pages,
  ) {
    final merged = <CategoryOption>[];
    final seen = <String>{};

    for (final raw in pages) {
      final options = CategoryService.instance._extractOptions(raw);
      for (final option in options) {
        final key = '${option.id}_${option.name.trim()}';
        if (seen.contains(key)) continue;
        seen.add(key);
        merged.add(option);
      }
    }

    return merged;
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
        .map((item) => CategoryOption.fromServerJson(
              Map<String, dynamic>.from(item),
            ))
        .where((option) => option.name.isNotEmpty)
        .toList();
  }
}
