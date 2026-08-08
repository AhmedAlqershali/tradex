import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/admin_review_model.dart';

class AdminReviewService {
  AdminReviewService._();

  static final AdminReviewService instance = AdminReviewService._();

  Future<AdminReviewPage> listReviews({
    required String productId,
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.adminProductReviews(productId),
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );
    final body = _map(response.data);
    final data = _map(body['data']);
    return AdminReviewPage(
      reviews: _list(data['data']).map(AdminReview.fromJson).toList(),
      pagination: AdminReviewPagination.fromJson(_map(data['pagination'])),
    );
  }

  Future<void> deleteReview(String reviewId) async {
    await ApiClient.instance
        .delete<Map<String, dynamic>>(ApiConstants.adminReviewById(reviewId));
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
}
