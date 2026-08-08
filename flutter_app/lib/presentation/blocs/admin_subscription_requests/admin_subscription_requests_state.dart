part of 'admin_subscription_requests_bloc.dart';

abstract class AdminSubscriptionRequestsState extends Equatable {
  const AdminSubscriptionRequestsState();

  @override
  List<Object?> get props => [];
}

class AdminSubscriptionRequestsInitial
    extends AdminSubscriptionRequestsState {
  const AdminSubscriptionRequestsInitial();
}

class AdminSubscriptionRequestsLoading
    extends AdminSubscriptionRequestsState {
  const AdminSubscriptionRequestsLoading({
    this.previousPage,
    this.selectedRequest,
    this.proofBytes,
  });

  final AdminSubscriptionRequestPage? previousPage;
  final AdminSubscriptionRequest? selectedRequest;
  final Uint8List? proofBytes;

  @override
  List<Object?> get props => [previousPage, selectedRequest, proofBytes];
}

class AdminSubscriptionRequestsLoaded
    extends AdminSubscriptionRequestsState {
  const AdminSubscriptionRequestsLoaded({
    required this.page,
    this.selectedRequest,
    this.proofBytes,
  });

  final AdminSubscriptionRequestPage page;
  final AdminSubscriptionRequest? selectedRequest;
  final Uint8List? proofBytes;

  @override
  List<Object?> get props => [page, selectedRequest, proofBytes];
}

class AdminSubscriptionRequestsFailure
    extends AdminSubscriptionRequestsState {
  const AdminSubscriptionRequestsFailure(
    this.message, {
    this.previousPage,
    this.selectedRequest,
    this.proofBytes,
  });

  final String message;
  final AdminSubscriptionRequestPage? previousPage;
  final AdminSubscriptionRequest? selectedRequest;
  final Uint8List? proofBytes;

  @override
  List<Object?> get props => [message, previousPage, selectedRequest, proofBytes];
}