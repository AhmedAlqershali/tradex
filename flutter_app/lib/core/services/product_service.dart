import 'package:dio/dio.dart';
import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/users/user_controller.dart';

// ─── ProductService ───────────────────────────────────────────────────────────
//
// Handles product catalog API calls (browsing + merchant CRUD).
//
// Endpoints:
//   GET    /products                (public browsing)
//   GET    /products/:id            (public browsing)
//   GET    /products/search?q=      (public browsing)
//   GET    /merchant/products       (merchant CRUD — separate namespace)
//   POST   /merchant/products
//   PUT    /merchant/products/:id
//   DELETE /merchant/products/:id
//   GET    /categories
//
// Merchant create/update requires store_id, category_id (int), quantity, and
// a status enum (active|inactive|out_of_stock) — there is no /products/:id
// /images sub-resource; images are uploaded as an `images[]` multipart field
// on the create/update request itself.
// ─────────────────────────────────────────────────────────────────────────────

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  // Cached name → id lookup so createProduct/updateProduct can accept a
  // category display name (as the existing screens already do) while still
  // sending the numeric category_id the backend requires.
  Map<String, String>? _categoryIdsByName;

  // ── Browse ────────────────────────────────────────────────────────────────────
  /// GET /products?category_id=&store_id=&search=&sort=&page=
  /// [category] is the display name shown in the UI; it's resolved to the
  /// numeric category_id the backend actually filters on.
  /// The backend has no "featured" concept, so [featured] is not sent.
  Future<List<Product>> getProducts({
    String? category,
    String? storeId,
    bool featured = false,
    int page = 1,
  }) async {
    final query = <String, dynamic>{'page': page};
    if (category != null && category.isNotEmpty) {
      final categoryId = await _resolveCategoryId(category);
      if (categoryId != null) query['category_id'] = categoryId;
    }
    if (storeId != null && storeId.isNotEmpty) query['store_id'] = storeId;

    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.products,
      queryParameters: query,
    );
    final raw = response.data!;
    return _extractProductList(raw);
  }

  /// GET /merchant/products
  ///
  /// This is intentionally separate from [getProducts], which reads the
  /// public catalog. Merchant screens must never use the public endpoint for
  /// their inventory.
  Future<List<Product>> getMerchantProducts() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.merchantProducts);
    return _extractProductList(response.data!);
  }

  /// GET /products/:id
  Future<Product> getProductById(String id) async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.productById(id));
    final raw = response.data!;
    final productJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return Product.fromServerJson(productJson);
  }

  /// GET /products?search=
  /// There is no separate /products/search route — search is a query
  /// parameter on the main listing endpoint.
  Future<List<Product>> search(String query) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.products,
      queryParameters: {'search': query},
    );
    final raw = response.data!;
    return _extractProductList(raw);
  }

  // ── Merchant CRUD ─────────────────────────────────────────────────────────────
  /// POST /merchant/products
  /// [category] is the display name shown in the UI; it's resolved to the
  /// numeric category_id the backend requires via [_resolveCategoryId].
  /// [quantity] defaults to 100 — the current product form has no stock-
  /// quantity field, so this is a stopgap until one is added; merchants can
  /// still adjust real stock levels once that field exists.
  /// [imagePaths] are attached as the `images[]` multipart field understood
  /// by the backend (there is no separate image sub-endpoint).
  Future<Product> createProduct({
    required String name,
    required String category,
    required double price,
    required String description,
    bool isVisible = true,
    bool isFeatured = false,
    int quantity = 100,
    List<String> imagePaths = const [],
  }) async {
    final storeId = UserController.instance.currentUser?.storeId;
    if (storeId == null || storeId.isEmpty) {
      throw const ValidationException('لا يوجد متجر مرتبط بهذا الحساب.');
    }
    final categoryId = await _resolveCategoryId(category);

    final formData = FormData.fromMap({
      'store_id': storeId,
      if (categoryId != null) 'category_id': categoryId,
      'name': name,
      'price': price,
      'description': description,
      'quantity': quantity,
      'status': isVisible ? 'active' : 'inactive',
      for (final path in imagePaths)
        'images[]': await MultipartFile.fromFile(path),
    });

    final response = await ApiClient.instance
        .postFormData<Map<String, dynamic>>(ApiConstants.merchantProducts, formData);
    final raw = response.data!;
    final productJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return Product.fromServerJson(productJson);
  }

  /// PUT /merchant/products/:id
  ///
  /// [imagePaths], when non-empty, *replaces the entire image gallery* — the
  /// backend has no per-image add/delete endpoint. Pass [clearImages]=true
  /// to remove all existing images without uploading new ones (e.g. the
  /// merchant deleted every existing photo and picked no replacement).
  Future<Product> updateProduct(
    String id, {
    String? name,
    String? category,
    double? price,
    String? description,
    bool? isVisible,
    bool? isFeatured,
    int? quantity,
    List<String> imagePaths = const [],
    bool clearImages = false,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (category != null) {
      final categoryId = await _resolveCategoryId(category);
      if (categoryId != null) body['category_id'] = categoryId;
    }
    if (price != null) body['price'] = price;
    if (description != null) body['description'] = description;
    if (isVisible != null) body['status'] = isVisible ? 'active' : 'inactive';
    if (quantity != null) body['quantity'] = quantity;

    if (imagePaths.isNotEmpty) {
      // PHP does not parse multipart bodies on PUT requests, so file
      // uploads on update must be sent as POST with Laravel's `_method`
      // override field (its standard workaround, supported out of the box).
      final formData = FormData.fromMap({
        ...body,
        '_method': 'PUT',
        for (final path in imagePaths)
          'images[]': await MultipartFile.fromFile(path),
      });
      final response = await ApiClient.instance.postFormData<Map<String, dynamic>>(
        ApiConstants.merchantProductById(id),
        formData,
      );
      final raw = response.data!;
      final productJson =
          raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
      return Product.fromServerJson(productJson);
    }

    if (clearImages) body['clear_images'] = true;

    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      ApiConstants.merchantProductById(id),
      data: body,
    );
    final raw = response.data!;
    final productJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return Product.fromServerJson(productJson);
  }

  /// DELETE /merchant/products/:id
  Future<void> deleteProduct(String id) async {
    await ApiClient.instance
        .delete<Map<String, dynamic>>(ApiConstants.merchantProductById(id));
  }

  // ── Config ────────────────────────────────────────────────────────────────────
  /// GET /categories
  Future<List<String>> getCategories() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.categories);
    final raw = response.data!;
    _cacheCategoryIds(raw);
    return _extractStringList(raw);
  }

  /// Resolves a category display name to the backend's numeric category_id,
  /// fetching and caching the category list on first use if needed. Returns
  /// null (silently) when the name can't be matched, so callers can still
  /// submit without a category rather than fail the whole request.
  Future<String?> _resolveCategoryId(String categoryName) async {
    if (categoryName.isEmpty) return null;
    if (_categoryIdsByName == null) {
      final response = await ApiClient.instance
          .get<Map<String, dynamic>>(ApiConstants.categories);
      _cacheCategoryIds(response.data!);
    }
    return _categoryIdsByName?[categoryName];
  }

  void _cacheCategoryIds(Map<String, dynamic> raw) {
    final data = raw['data'] ?? raw;
    final list = data is Map && data['data'] is List ? data['data'] : data;
    if (list is List) {
      _categoryIdsByName = {
        for (final e in list)
          if (e is Map && e['name'] != null)
            e['name'].toString(): e['id'].toString(),
      };
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  List<Product> _extractProductList(Map<String, dynamic> raw) {
    final data = raw['data'] ?? raw;
    if (data is List) {
      return data
          .cast<Map<String, dynamic>>()
          .map(Product.fromServerJson)
          .toList();
    }
    // Paginated: data.data is the list.
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .cast<Map<String, dynamic>>()
          .map(Product.fromServerJson)
          .toList();
    }
    return [];
  }

  List<String> _extractStringList(Map<String, dynamic> raw) {
    final outer = raw['data'] ?? raw;
    final data = (outer is Map && outer['data'] is List) ? outer['data'] : outer;
    if (data is List) {
      return data.map((e) {
        if (e is String) return e;
        if (e is Map) {
          return (e['name'] ?? e['label'] ?? e['value'] ?? '').toString();
        }
        return e.toString();
      }).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
}
