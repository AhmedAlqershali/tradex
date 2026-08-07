part of 'admin_users_bloc.dart';

abstract class AdminUsersEvent extends Equatable {
  const AdminUsersEvent();

  @override
  List<Object?> get props => [];
}

class AdminUsersLoadRequested extends AdminUsersEvent {
  const AdminUsersLoadRequested();
}

class AdminUsersSearchChanged extends AdminUsersEvent {
  const AdminUsersSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

class AdminUsersRoleFilterChanged extends AdminUsersEvent {
  const AdminUsersRoleFilterChanged(this.role);

  final String? role;

  @override
  List<Object?> get props => [role];
}

class AdminUsersStatusFilterChanged extends AdminUsersEvent {
  const AdminUsersStatusFilterChanged(this.status);

  final String? status;

  @override
  List<Object?> get props => [status];
}

class AdminUsersPageRequested extends AdminUsersEvent {
  const AdminUsersPageRequested(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

class AdminUserDetailsRequested extends AdminUsersEvent {
  const AdminUserDetailsRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class AdminUserRoleUpdateRequested extends AdminUsersEvent {
  const AdminUserRoleUpdateRequested({
    required this.userId,
    required this.role,
  });

  final String userId;
  final String role;

  @override
  List<Object?> get props => [userId, role];
}

class AdminUserStatusUpdateRequested extends AdminUsersEvent {
  const AdminUserStatusUpdateRequested({
    required this.userId,
    required this.status,
  });

  final String userId;
  final String status;

  @override
  List<Object?> get props => [userId, status];
}

class AdminUserDeleteRequested extends AdminUsersEvent {
  const AdminUserDeleteRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}
