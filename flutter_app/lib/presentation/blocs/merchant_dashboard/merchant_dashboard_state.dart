part of 'merchant_dashboard_bloc.dart';

abstract class MerchantDashboardState extends Equatable {
  const MerchantDashboardState();

  @override
  List<Object?> get props => [];
}

class MerchantDashboardInitial extends MerchantDashboardState {
  const MerchantDashboardInitial();
}

class MerchantDashboardLoading extends MerchantDashboardState {
  const MerchantDashboardLoading();
}

class MerchantDashboardLoaded extends MerchantDashboardState {
  const MerchantDashboardLoaded(this.dashboard);

  final MerchantDashboardModel dashboard;

  @override
  List<Object?> get props => [dashboard];
}

class MerchantDashboardFailure extends MerchantDashboardState {
  const MerchantDashboardFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}