part of 'admin_merchants_bloc.dart';

abstract class AdminMerchantsState extends Equatable {
  const AdminMerchantsState();

  @override
  List<Object?> get props => [];
}

class AdminMerchantsInitial extends AdminMerchantsState {
  const AdminMerchantsInitial();
}

class AdminMerchantsLoading extends AdminMerchantsState {
  const AdminMerchantsLoading({
    this.previousPage,
    this.selectedMerchant,
  });

  final AdminMerchantPage? previousPage;
  final AdminMerchant? selectedMerchant;

  @override
  List<Object?> get props => [previousPage, selectedMerchant];
}

class AdminMerchantsLoaded extends AdminMerchantsState {
  const AdminMerchantsLoaded({
    required this.page,
    this.selectedMerchant,
  });

  final AdminMerchantPage page;
  final AdminMerchant? selectedMerchant;

  @override
  List<Object?> get props => [page, selectedMerchant];
}

class AdminMerchantsFailure extends AdminMerchantsState {
  const AdminMerchantsFailure(
    this.message, {
    this.previousPage,
    this.selectedMerchant,
  });

  final String message;
  final AdminMerchantPage? previousPage;
  final AdminMerchant? selectedMerchant;

  @override
  List<Object?> get props => [message, previousPage, selectedMerchant];
}