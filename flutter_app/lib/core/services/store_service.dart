import 'package:dio/dio.dart';
import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/core/services/product_service.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/models/store_model.dart';

// ─── StoreService ─────────────────────────────────────────────────────────────
//
// Handles store browsing and merchant-owned store management.
//
// Endpoints:
//   GET  /stores                    (public browsing, paginated)
//   GET  /stores/:id                (public browsing)
//   GET  /stores/:id/products       (public browsing, paginated)
//   GET  /merchant/stores           (merchant — list own store(s))
//   PUT  /merchant/stores/:id
//   POST /merchant/stores/:id/logo
// ─────────────────────────────────────────────────────────────────────────────

class StoreService {
  StoreService._();
  static final StoreService instance = StoreService._();

  // ── Browse ────────────────────────────────────────────────────────────────────
  /// GET /stores
  Future<List<StoreModel>> getAllStores({String? region}) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.stores,
      queryParameters: {
        if (region != null && region.trim().isNotEmpty) 'region': region,
      },
    );
    final raw = response.data!;
    final list = _extractList(raw);
    return list.map((e) => StoreModel.fromServerJson(e)).toList();
  }

  /// GET /stores/:id
  Future<StoreModel> getStoreById(String id) async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.storeById(id));
    final raw = response.data!;
    final storeJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return StoreModel.fromServerJson(storeJson);
  }

  // ── Merchant own store ────────────────────────────────────────────────────────
  // Backend has no "/stores/me" shortcut — every merchant store route is
  // id-based (a merchant's store id is captured at registration time and
  // stored on AppUser.storeId).

  /// GET /merchant/stores — returns the authenticated merchant's stores;
  /// this app only ever creates one per merchant, so the first is "my store".
  Future<StoreModel> getMyStore() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.myStores);
    final raw = response.data!;
    final list = _extractList(raw);
    if (list.isEmpty) {
      throw StateError('No store found for the current merchant.');
    }
    return StoreModel.fromServerJson(list.first);
  }

  /// POST /merchant/stores — returns the existing store when one is present.
  Future<StoreModel> createMyStore({
    required String name,
    String? region,
  }) async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.myStores,
      data: {
        'store_name': name,
        if (region != null) 'region': region,
      },
    );
    final raw = response.data!;
    final storeJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return StoreModel.fromServerJson(storeJson);
  }

  /// PUT /merchant/stores/:id
  /// Backend accepts store_name, description, region, and phone.
  Future<StoreModel> updateMyStore({
    required String storeId,
    String? name,
    String? description,
    String? region,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['store_name'] = name;
    if (description != null) body['description'] = description;
    if (region != null) body['region'] = region;
    if (phone != null) body['phone'] = phone;

    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      ApiConstants.myStoreById(storeId),
      data: body,
    );
    final raw = response.data!;
    final storeJson =
        raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return StoreModel.fromServerJson(storeJson);
  }

  /// POST /merchant/stores/:id/logo
  Future<String> uploadStoreLogo({
    required String storeId,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'logo': await MultipartFile.fromFile(filePath),
    });
    final response =
        await ApiClient.instance.postFormData<Map<String, dynamic>>(
      ApiConstants.myStoreLogo(storeId),
      formData,
    );
    final raw = response.data!;
    final body = raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
    return body['logo'] as String? ??
        body['logo_url'] as String? ??
        body['url'] as String? ??
        '';
  }

  // ── Store products ────────────────────────────────────────────────────────────
  /// GET /stores/:id/products
  Future<List<Product>> getStoreProducts(String storeId) async {
    // There is no /stores/{id}/products route. The supported client catalog
    // endpoint exposes store_id filtering.
    return ProductService.instance.getProducts(storeId: storeId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> raw) {
    final outer = raw['data'] ?? raw;
    final data =
        (outer is Map && outer['data'] is List) ? outer['data'] : outer;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
