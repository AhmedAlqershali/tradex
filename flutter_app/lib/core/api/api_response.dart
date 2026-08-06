// ─── ApiResponse ──────────────────────────────────────────────────────────────
//
// Generic wrapper for every successful response returned by the backend.
// Services parse the raw Dio response into ApiResponse<T>, and controllers
// receive typed data without knowing anything about HTTP or JSON.
//
// Expected server envelope:
// {
//   "success": true,
//   "message": "...",
//   "data": { ... }          // single object
// }
// or for paginated lists:
// {
//   "success": true,
//   "message": "...",
//   "data": [ ... ],
//   "meta": { "total": 100, "page": 1, "perPage": 20 }
// }
// ─────────────────────────────────────────────────────────────────────────────

class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
    this.meta,
  });

  final bool success;
  final String message;
  final T data;
  final PaginationMeta? meta;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      data: fromData(json['data']),
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── Pagination metadata ───────────────────────────────────────────────────────

class PaginationMeta {
  const PaginationMeta({
    required this.total,
    required this.page,
    required this.perPage,
  });

  final int total;
  final int page;
  final int perPage;

  int get totalPages => (total / perPage).ceil();
  bool get hasNextPage => page < totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total:   (json['total']   as num?)?.toInt() ?? 0,
      page:    (json['page']    as num?)?.toInt() ?? 1,
      perPage: (json['perPage'] as num?)?.toInt() ?? 20,
    );
  }
}
