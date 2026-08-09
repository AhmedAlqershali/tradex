part of 'client_dashboard_bloc.dart';

abstract class ClientDashboardState extends Equatable {
  const ClientDashboardState();

  @override
  List<Object?> get props => [];
}

class ClientDashboardInitial extends ClientDashboardState {
  const ClientDashboardInitial();
}

class ClientDashboardLoading extends ClientDashboardState {
  const ClientDashboardLoading();
}

class ClientDashboardLoaded extends ClientDashboardState {
  const ClientDashboardLoaded(this.dashboard);

  final ClientDashboardModel dashboard;

  @override
  List<Object?> get props => [dashboard];
}

class ClientDashboardFailure extends ClientDashboardState {
  const ClientDashboardFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
