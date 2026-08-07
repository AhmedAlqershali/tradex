import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/admin_user_service.dart';
import 'package:ai_saas/shared/models/admin_user_model.dart';

part 'admin_users_event.dart';
part 'admin_users_state.dart';

class AdminUsersBloc extends Bloc<AdminUsersEvent, AdminUsersState> {
  AdminUsersBloc() : super(const AdminUsersInitial()) {
    on<AdminUsersLoadRequested>(_onLoadRequested);
    on<AdminUsersSearchChanged>(_onSearchChanged);
    on<AdminUsersRoleFilterChanged>(_onRoleFilterChanged);
    on<AdminUsersStatusFilterChanged>(_onStatusFilterChanged);
    on<AdminUsersPageRequested>(_onPageRequested);
    on<AdminUserDetailsRequested>(_onDetailsRequested);
    on<AdminUserRoleUpdateRequested>(_onRoleUpdateRequested);
    on<AdminUserStatusUpdateRequested>(_onStatusUpdateRequested);
    on<AdminUserDeleteRequested>(_onDeleteRequested);
  }

  String _search = '';
  String? _role;
  String? _status;
  int _page = 1;
  static const _perPage = 15;
  AdminUser? _selectedUser;

  Future<void> _onLoadRequested(
    AdminUsersLoadRequested event,
    Emitter<AdminUsersState> emit,
  ) async {
    _page = 1;
    _selectedUser = null;
    await _fetch(emit);
  }

  Future<void> _onSearchChanged(
    AdminUsersSearchChanged event,
    Emitter<AdminUsersState> emit,
  ) async {
    _search = event.search.trim();
    _page = 1;
    _selectedUser = null;
    await _fetch(emit);
  }

  Future<void> _onRoleFilterChanged(
    AdminUsersRoleFilterChanged event,
    Emitter<AdminUsersState> emit,
  ) async {
    _role = event.role;
    _page = 1;
    _selectedUser = null;
    await _fetch(emit);
  }

  Future<void> _onStatusFilterChanged(
    AdminUsersStatusFilterChanged event,
    Emitter<AdminUsersState> emit,
  ) async {
    _status = event.status;
    _page = 1;
    _selectedUser = null;
    await _fetch(emit);
  }

  Future<void> _onPageRequested(
    AdminUsersPageRequested event,
    Emitter<AdminUsersState> emit,
  ) async {
    _page = event.page;
    _selectedUser = null;
    await _fetch(emit);
  }

  Future<void> _onDetailsRequested(
    AdminUserDetailsRequested event,
    Emitter<AdminUsersState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminUsersLoading(previousPage: previous));
    try {
      _selectedUser = await AdminUserService.instance.getUser(event.userId);
      if (!isClosed) {
        emit(AdminUsersLoaded(
          page: previous ??
              const AdminUserPage(
                users: [],
                pagination: AdminUserPagination(
                  total: 0,
                  perPage: _perPage,
                  currentPage: 1,
                  lastPage: 1,
                ),
              ),
          selectedUser: _selectedUser,
        ));
      }
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(AdminUsersFailure(e.message, previousPage: previous));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminUsersFailure(e.toString(), previousPage: previous));
      }
    }
  }

  Future<void> _onRoleUpdateRequested(
    AdminUserRoleUpdateRequested event,
    Emitter<AdminUsersState> emit,
  ) async {
    await _performAction(
      emit,
      () => AdminUserService.instance.updateRole(event.userId, event.role),
    );
  }

  Future<void> _onStatusUpdateRequested(
    AdminUserStatusUpdateRequested event,
    Emitter<AdminUsersState> emit,
  ) async {
    await _performAction(
      emit,
      () => AdminUserService.instance.updateStatus(event.userId, event.status),
    );
  }

  Future<void> _onDeleteRequested(
    AdminUserDeleteRequested event,
    Emitter<AdminUsersState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminUsersLoading(
      previousPage: previous,
      selectedUser: _selectedUser,
    ));
    try {
      await AdminUserService.instance.deleteUser(event.userId);
      _selectedUser = null;
      await _fetch(emit);
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(AdminUsersFailure(
          e.message,
          previousPage: previous,
          selectedUser: _selectedUser,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminUsersFailure(
          e.toString(),
          previousPage: previous,
          selectedUser: _selectedUser,
        ));
      }
    }
  }

  Future<void> _performAction(
    Emitter<AdminUsersState> emit,
    Future<AdminUser> Function() action,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminUsersLoading(
      previousPage: previous,
      selectedUser: _selectedUser,
    ));
    try {
      _selectedUser = await action();
      await _fetch(emit, keepSelectedUser: true);
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(AdminUsersFailure(
          e.message,
          previousPage: previous,
          selectedUser: _selectedUser,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminUsersFailure(
          e.toString(),
          previousPage: previous,
          selectedUser: _selectedUser,
        ));
      }
    }
  }

  Future<void> _fetch(
    Emitter<AdminUsersState> emit, {
    bool keepSelectedUser = false,
  }) async {
    final previous = _pageFromState(state);
    emit(AdminUsersLoading(
      previousPage: previous,
      selectedUser: keepSelectedUser ? _selectedUser : null,
    ));
    try {
      final page = await AdminUserService.instance.listUsers(
        search: _search,
        role: _role,
        status: _status,
        page: _page,
        perPage: _perPage,
      );
      if (!keepSelectedUser) _selectedUser = null;
      if (!isClosed) {
        emit(AdminUsersLoaded(page: page, selectedUser: _selectedUser));
      }
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(AdminUsersFailure(
          e.message,
          previousPage: previous,
          selectedUser: _selectedUser,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminUsersFailure(
          e.toString(),
          previousPage: previous,
          selectedUser: _selectedUser,
        ));
      }
    }
  }

  AdminUserPage? _pageFromState(AdminUsersState current) {
    if (current is AdminUsersLoaded) return current.page;
    if (current is AdminUsersLoading) return current.previousPage;
    if (current is AdminUsersFailure) return current.previousPage;
    return null;
  }
}
