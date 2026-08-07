part of 'admin_dashboard_bloc.dart';

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();

  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardLoaded extends AdminDashboardState {
  const AdminDashboardLoaded(this.dashboard);

  final AdminDashboardModel dashboard;

  @override
  List<Object?> get props => [dashboard];
}

class AdminDashboardFailure extends AdminDashboardState {
  const AdminDashboardFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
