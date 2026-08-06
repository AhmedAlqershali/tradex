part of 'merchant_bloc.dart';

abstract class MerchantState extends Equatable {
  const MerchantState();

  @override
  List<Object?> get props => [];
}

class MerchantInitial extends MerchantState {
  const MerchantInitial();
}

class MerchantLoading extends MerchantState {
  const MerchantLoading();
}

/// Logo has been uploaded; [logoUrl] is the hosted network URL.
class MerchantLogoUploaded extends MerchantState {
  const MerchantLogoUploaded(this.logoUrl);

  final String logoUrl;

  @override
  List<Object?> get props => [logoUrl];
}

/// Store profile was created/updated successfully.
class MerchantStoreSetupComplete extends MerchantState {
  const MerchantStoreSetupComplete(this.store);

  final StoreModel store;

  @override
  List<Object?> get props => [store];
}

class MerchantFailure extends MerchantState {
  const MerchantFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
