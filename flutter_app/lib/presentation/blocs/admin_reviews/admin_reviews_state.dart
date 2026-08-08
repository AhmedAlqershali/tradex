part of 'admin_reviews_bloc.dart';

abstract class AdminReviewsState extends Equatable {
  const AdminReviewsState();

  @override
  List<Object?> get props => [];
}

class AdminReviewsInitial extends AdminReviewsState {
  const AdminReviewsInitial();
}

class AdminReviewsLoading extends AdminReviewsState {
  const AdminReviewsLoading({
    this.previousPage,
    required this.productId,
  });

  final AdminReviewPage? previousPage;
  final String productId;

  @override
  List<Object?> get props => [previousPage, productId];
}

class AdminReviewsLoaded extends AdminReviewsState {
  const AdminReviewsLoaded({
    required this.page,
    required this.productId,
  });

  final AdminReviewPage page;
  final String productId;

  @override
  List<Object?> get props => [page, productId];
}

class AdminReviewsFailure extends AdminReviewsState {
  const AdminReviewsFailure(
    this.message, {
    this.previousPage,
    required this.productId,
  });

  final String message;
  final AdminReviewPage? previousPage;
  final String productId;

  @override
  List<Object?> get props => [message, previousPage, productId];
}
