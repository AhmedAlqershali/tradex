part of 'merchant_subscription_bloc.dart';

abstract class MerchantSubscriptionState extends Equatable {
  const MerchantSubscriptionState();

  @override
  List<Object?> get props => [];
}

class MerchantSubscriptionInitial extends MerchantSubscriptionState {
  const MerchantSubscriptionInitial();
}

class MerchantSubscriptionLoading extends MerchantSubscriptionState {
  const MerchantSubscriptionLoading();
}

class MerchantSubscriptionLoaded extends MerchantSubscriptionState {
  const MerchantSubscriptionLoaded(
    this.subscription, {
    this.requests = const [],
    this.requestsLoading = false,
    this.submitting = false,
    this.selectedRequest,
    this.detailsLoading = false,
    this.submissionMessage,
  });

  final AdminSubscription? subscription;
  final List<AdminSubscriptionRequest> requests;
  final bool requestsLoading;
  final bool submitting;
  final AdminSubscriptionRequest? selectedRequest;
  final bool detailsLoading;
  final String? submissionMessage;

  @override
  List<Object?> get props => [
        subscription,
        requests,
        requestsLoading,
        submitting,
        selectedRequest,
        detailsLoading,
        submissionMessage,
      ];
}

class MerchantSubscriptionFailure extends MerchantSubscriptionState {
  const MerchantSubscriptionFailure(
    this.message, {
    this.subscription,
    this.requests = const [],
    this.selectedRequest,
  });

  final String message;
  final AdminSubscription? subscription;
  final List<AdminSubscriptionRequest> requests;
  final AdminSubscriptionRequest? selectedRequest;

  @override
  List<Object?> get props => [
        message,
        subscription,
        requests,
        selectedRequest,
      ];
}
