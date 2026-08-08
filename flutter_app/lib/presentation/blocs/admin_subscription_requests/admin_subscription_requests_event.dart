part of 'admin_subscription_requests_bloc.dart';

abstract class AdminSubscriptionRequestsEvent extends Equatable {
  const AdminSubscriptionRequestsEvent();

  @override
  List<Object?> get props => [];
}

class AdminSubscriptionRequestsLoadRequested
    extends AdminSubscriptionRequestsEvent {
  const AdminSubscriptionRequestsLoadRequested();
}

class AdminSubscriptionRequestsStatusChanged
    extends AdminSubscriptionRequestsEvent {
  const AdminSubscriptionRequestsStatusChanged(this.status);

  final String? status;

  @override
  List<Object?> get props => [status];
}

class AdminSubscriptionRequestsPageRequested
    extends AdminSubscriptionRequestsEvent {
  const AdminSubscriptionRequestsPageRequested(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

class AdminSubscriptionRequestDetailsRequested
    extends AdminSubscriptionRequestsEvent {
  const AdminSubscriptionRequestDetailsRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class AdminSubscriptionRequestProofRequested
    extends AdminSubscriptionRequestsEvent {
  const AdminSubscriptionRequestProofRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class AdminSubscriptionRequestApproveRequested
    extends AdminSubscriptionRequestsEvent {
  const AdminSubscriptionRequestApproveRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class AdminSubscriptionRequestRejectRequested
    extends AdminSubscriptionRequestsEvent {
  const AdminSubscriptionRequestRejectRequested(this.id, this.reason);

  final String id;
  final String reason;

  @override
  List<Object?> get props => [id, reason];
}