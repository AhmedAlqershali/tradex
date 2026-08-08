part of 'admin_reviews_bloc.dart';

abstract class AdminReviewsEvent extends Equatable {
  const AdminReviewsEvent();

  @override
  List<Object?> get props => [];
}

class AdminReviewsLoadRequested extends AdminReviewsEvent {
  const AdminReviewsLoadRequested(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

class AdminReviewsPageRequested extends AdminReviewsEvent {
  const AdminReviewsPageRequested(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

class AdminReviewDeleteRequested extends AdminReviewsEvent {
  const AdminReviewDeleteRequested(this.reviewId);

  final String reviewId;

  @override
  List<Object?> get props => [reviewId];
}
