import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/admin_subscription_request_model.dart';

class AdminSubscriptionRequestService {
  AdminSubscriptionRequestService._();

  static final AdminSubscriptionRequestService instance =
      AdminSubscriptionRequestService._();

  Future<AdminSubscriptionRequestPage> listRequests({
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.adminSubscriptionRequests,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final body = _map(response.data);
    final data = _map(body['data']);
    return AdminSubscriptionRequestPage(
      requests: _list(data['data'])
          .map(AdminSubscriptionRequest.fromJson)
          .toList(),
      pagination: AdminSubscriptionRequestPagination.fromJson(
        _map(data['pagination']),
      ),
    );
  }

  Future<AdminSubscriptionRequest> getRequest(String id) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.adminSubscriptionRequestById(id),
    );
    return AdminSubscriptionRequest.fromJson(
      _map(_map(response.data)['data']),
    );
  }

  Future<AdminSubscriptionRequest> approve(String id) async {
    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      ApiConstants.adminSubscriptionRequestApprove(id),
    );
    return AdminSubscriptionRequest.fromJson(
      _map(_map(response.data)['data']),
    );
  }

  Future<AdminSubscriptionRequest> reject(
    String id,
    String rejectionReason,
  ) async {
    final response = await ApiClient.instance.put<Map<String, dynamic>>(
      ApiConstants.adminSubscriptionRequestReject(id),
      data: {'rejection_reason': rejectionReason},
    );
    return AdminSubscriptionRequest.fromJson(
      _map(_map(response.data)['data']),
    );
  }

  Future<Uint8List> downloadProof(String id) async {
    final response = await ApiClient.instance.get<List<int>>(
      ApiConstants.adminSubscriptionRequestProof(id),
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}