part of 'merchant_dashboard_bloc.dart';

abstract class MerchantDashboardEvent extends Equatable {
  const MerchantDashboardEvent();

  @override
  List<Object?> get props => [];
}

class MerchantDashboardLoadRequested extends MerchantDashboardEvent {
  const MerchantDashboardLoadRequested();
}