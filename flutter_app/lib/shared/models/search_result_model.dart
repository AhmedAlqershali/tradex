import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/models/store_model.dart';

class UnifiedSearchResult {
  const UnifiedSearchResult({required this.products, required this.stores});

  final List<Product> products;
  final List<StoreModel> stores;

  factory UnifiedSearchResult.fromServerJson(Map<String, dynamic> json) {
    final raw = json['data'] is Map
        ? json['data'] as Map<String, dynamic>
        : json;
    return UnifiedSearchResult(
      products: _extract(raw['products'], Product.fromServerJson),
      stores: _extract(raw['stores'], StoreModel.fromServerJson),
    );
  }

  static List<T> _extract<T>(dynamic value, T Function(Map<String, dynamic>) parse) {
    final data = value is Map && value['data'] is List ? value['data'] : value;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => parse(Map<String, dynamic>.from(item)))
        .toList();
  }
}