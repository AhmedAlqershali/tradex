part of 'merchant_subscription_bloc.dart';

abstract class MerchantSubscriptionEvent extends Equatable {
  const MerchantSubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class MerchantSubscriptionLoadRequested extends MerchantSubscriptionEvent {
  const MerchantSubscriptionLoadRequested();
}
