class AdminReview {
  const AdminReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.reviewer,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String? comment;
  final AdminReviewReviewer? reviewer;
  final DateTime? createdAt;

  factory AdminReview.fromJson(Map<String, dynamic> json) {
    final rawReviewer = json['reviewer'];
    return AdminReview(
      id: _text(json['id']),
      rating: _integer(json['rating']),
      comment: json['comment']?.toString(),
      reviewer: rawReviewer is Map
          ? AdminReviewReviewer.fromJson(Map<String, dynamic>.from(rawReviewer))
          : null,
      createdAt: _date(json['created_at']),
    );
  }
}

class AdminReviewReviewer {
  const AdminReviewReviewer({
    required this.id,
    required this.name,
    required this.avatar,
  });

  final String id;
  final String name;
  final String? avatar;

  factory AdminReviewReviewer.fromJson(Map<String, dynamic> json) {
    return AdminReviewReviewer(
      id: _text(json['id']),
      name: _text(json['name'], fallback: 'مستخدم'),
      avatar: json['avatar']?.toString(),
    );
  }
}

class AdminReviewPage {
  const AdminReviewPage({
    required this.reviews,
    required this.pagination,
  });

  final List<AdminReview> reviews;
  final AdminReviewPagination pagination;

  bool get isEmpty => reviews.isEmpty;
}

class AdminReviewPagination {
  const AdminReviewPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  bool get hasPrevious => currentPage > 1;
  bool get hasNext => currentPage < lastPage;

  factory AdminReviewPagination.fromJson(Map<String, dynamic> json) {
    return AdminReviewPagination(
      total: _integer(json['total']),
      perPage: _integer(json['per_page'], fallback: 15),
      currentPage: _integer(json['current_page'], fallback: 1),
      lastPage: _integer(json['last_page'], fallback: 1),
    );
  }
}

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _integer(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

DateTime? _date(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? null : DateTime.tryParse(text);
}
