import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/admin_subscription_model.dart';
import 'package:ai_saas/shared/models/admin_subscription_request_model.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Reads the authenticated merchant's current trial or paid subscription.
///
/// Subscription changes remain an admin/backend responsibility. This client
/// only consumes the existing GET /merchant/subscription endpoint.
class MerchantSubscriptionService {
  MerchantSubscriptionService._();

  static final MerchantSubscriptionService instance =
      MerchantSubscriptionService._();

  Future<AdminSubscription?> getCurrentSubscription() async {
    final response = await ApiClient.instance
        .get<Map<String, dynamic>>(ApiConstants.merchantSubscription);
    final raw = response.data;
    final data = raw?['data'];

    if (data == null) return null;
    if (data is! Map) {
      throw const FormatException('Merchant subscription data was malformed.');
    }

    return AdminSubscription.fromJson(Map<String, dynamic>.from(data));
  }

  /// GET /merchant/subscription-requests
  ///
  /// The merchant endpoint returns a plain list inside the standard `data`
  /// envelope (unlike the paginated admin endpoint).
  Future<List<AdminSubscriptionRequest>> listRequests() async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.merchantSubscriptionRequests,
    );
    final body = _map(response.data);
    final rawData = body['data'];
    final list = rawData is List
        ? rawData
        : rawData is Map
            ? rawData['data']
            : null;

    if (list is! List) {
      throw const FormatException(
        'Merchant subscription requests data was malformed.',
      );
    }

    return list
        .whereType<Map>()
        .map((item) =>
            AdminSubscriptionRequest.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// GET /merchant/subscription-requests/:id
  Future<AdminSubscriptionRequest> getRequest(String id) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.merchantSubscriptionRequestById(id),
    );
    final body = _map(response.data);
    final data = body['data'];
    if (data is! Map) {
      throw const FormatException(
        'Merchant subscription request data was malformed.',
      );
    }
    return AdminSubscriptionRequest.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  /// POST /merchant/subscription-requests
  ///
  /// The proof is sent as bytes so this remains compatible with mobile,
  /// desktop, and Flutter web image-picker implementations.
  Future<AdminSubscriptionRequest> submitRequest({
    required int planId,
    required String billingCycle,
    required String fullName,
    required String phone,
    required String paymentMethod,
    required XFile paymentProof,
    String? notes,
  }) async {
    final proofBytes = await paymentProof.readAsBytes();
    final formData = FormData.fromMap({
      'plan_id': planId,
      'billing_cycle': billingCycle,
      'full_name': fullName,
      'phone': phone,
      'payment_method': paymentMethod,
      'payment_proof_image': MultipartFile.fromBytes(
        proofBytes,
        filename:
            paymentProof.name.isEmpty ? 'payment-proof.jpg' : paymentProof.name,
      ),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });

    final response =
        await ApiClient.instance.postFormData<Map<String, dynamic>>(
      ApiConstants.merchantSubscriptionRequests,
      formData,
    );
    final body = _map(response.data);
    final data = body['data'];
    if (data is! Map) {
      throw const FormatException(
        'Submitted subscription request data was malformed.',
      );
    }
    return AdminSubscriptionRequest.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}
