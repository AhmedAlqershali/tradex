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
  const MerchantSubscriptionLoaded(this.subscription);

  final AdminSubscription? subscription;

  @override
  List<Object?> get props => [subscription];
}

class MerchantSubscriptionFailure extends MerchantSubscriptionState {
  const MerchantSubscriptionFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
