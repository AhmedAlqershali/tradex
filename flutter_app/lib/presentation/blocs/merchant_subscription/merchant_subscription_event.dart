part of 'merchant_subscription_bloc.dart';

abstract class MerchantSubscriptionEvent extends Equatable {
  const MerchantSubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class MerchantSubscriptionLoadRequested extends MerchantSubscriptionEvent {
  const MerchantSubscriptionLoadRequested();
}

class MerchantSubscriptionPlansLoadRequested
    extends MerchantSubscriptionEvent {
  const MerchantSubscriptionPlansLoadRequested();
}

class MerchantSubscriptionRequestsLoadRequested
    extends MerchantSubscriptionEvent {
  const MerchantSubscriptionRequestsLoadRequested();
}

class MerchantSubscriptionRequestDetailsRequested
    extends MerchantSubscriptionEvent {
  const MerchantSubscriptionRequestDetailsRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class MerchantSubscriptionRequestSubmitRequested
    extends MerchantSubscriptionEvent {
  const MerchantSubscriptionRequestSubmitRequested({
    required this.planId,
    required this.billingCycle,
    required this.fullName,
    required this.phone,
    required this.paymentMethod,
    required this.paymentProof,
    this.notes,
  });

  final int planId;
  final String billingCycle;
  final String fullName;
  final String phone;
  final String paymentMethod;
  final XFile paymentProof;
  final String? notes;

  @override
  List<Object?> get props => [
        planId,
        billingCycle,
        fullName,
        phone,
        paymentMethod,
        paymentProof.path,
        notes,
      ];
}
