part of 'admin_users_bloc.dart';

abstract class AdminUsersState extends Equatable {
  const AdminUsersState();

  @override
  List<Object?> get props => [];
}

class AdminUsersInitial extends AdminUsersState {
  const AdminUsersInitial();
}

class AdminUsersLoading extends AdminUsersState {
  const AdminUsersLoading({
    this.previousPage,
    this.selectedUser,
  });

  final AdminUserPage? previousPage;
  final AdminUser? selectedUser;

  @override
  List<Object?> get props => [previousPage, selectedUser];
}

class AdminUsersLoaded extends AdminUsersState {
  const AdminUsersLoaded({
    required this.page,
    this.selectedUser,
  });

  final AdminUserPage page;
  final AdminUser? selectedUser;

  @override
  List<Object?> get props => [page, selectedUser];
}

class AdminUsersFailure extends AdminUsersState {
  const AdminUsersFailure(
    this.message, {
    this.previousPage,
    this.selectedUser,
  });

  final String message;
  final AdminUserPage? previousPage;
  final AdminUser? selectedUser;

  @override
  List<Object?> get props => [message, previousPage, selectedUser];
}
