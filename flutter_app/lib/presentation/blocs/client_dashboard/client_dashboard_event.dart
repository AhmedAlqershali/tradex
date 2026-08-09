part of 'client_dashboard_bloc.dart';

abstract class ClientDashboardEvent extends Equatable {
  const ClientDashboardEvent();

  @override
  List<Object?> get props => [];
}

class ClientDashboardLoadRequested extends ClientDashboardEvent {
  const ClientDashboardLoadRequested();
}
