// ─── ApiResponse ──────────────────────────────────────────────────────────────
//
// Generic wrapper for every successful response returned by the backend.
// Services parse the raw Dio response into ApiResponse<T>, and controllers
// receive typed data without knowing anything about HTTP or JSON.
//
// Expected server envelope for single objects:
// {
//   "success": true,
//   "message": "...",
//   "data": { ... }
// }
//
// Expected server envelope for paginated collections:
// {
//   "success": true,
//   "message": "...",
//   "data": {
//     "data": [ ... ],
//     "pagination": {
//       "total": 100,
//       "per_page": 20,
//       "current_page": 1,
//       "last_page": 5
//     }
//   }
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
    // Pagination is nested inside `data.pagination` for collection responses.
    // Check there first, then fall back to a top-level `meta` key for any
    // future endpoint that uses a flat envelope.
    PaginationMeta? meta;
    final dataRaw = json['data'];
    if (dataRaw is Map && dataRaw['pagination'] is Map) {
      meta = PaginationMeta.fromJson(
          dataRaw['pagination'] as Map<String, dynamic>);
    } else if (json['meta'] is Map) {
      meta = PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>);
    }

    return ApiResponse<T>(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      data: fromData(dataRaw),
      meta: meta,
    );
  }
}

// ── Pagination metadata ───────────────────────────────────────────────────────

class PaginationMeta {
  const PaginationMeta({
    required this.total,
    required this.page,
    required this.perPage,
    this.lastPage,
  });

  final int total;
  final int page;
  final int perPage;

  /// Backend-provided last page number. Falls back to a computed value when
  /// not present in the response.
  final int? lastPage;

  int get totalPages => lastPage ?? (perPage > 0 ? (total / perPage).ceil() : 1);
  bool get hasNextPage => page < totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total:    (json['total']        as num?)?.toInt() ?? 0,
      // Backend sends `current_page`; accept `page` as a camelCase fallback.
      page:     (json['current_page'] as num?)?.toInt() ??
                (json['page']         as num?)?.toInt() ?? 1,
      // Backend sends `per_page`; accept `perPage` as a camelCase fallback.
      perPage:  (json['per_page']     as num?)?.toInt() ??
                (json['perPage']      as num?)?.toInt() ?? 20,
      lastPage: (json['last_page']    as num?)?.toInt(),
    );
  }
}
