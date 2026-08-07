import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/admin_dashboard_service.dart';
import 'package:ai_saas/shared/models/admin_dashboard_model.dart';

part 'admin_dashboard_event.dart';
part 'admin_dashboard_state.dart';

class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  AdminDashboardBloc() : super(const AdminDashboardInitial()) {
    on<AdminDashboardLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    AdminDashboardLoadRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(const AdminDashboardLoading());
    try {
      final dashboard = await AdminDashboardService.instance.getDashboard();
      if (!isClosed) emit(AdminDashboardLoaded(dashboard));
    } on ApiException catch (e) {
      if (!isClosed) emit(AdminDashboardFailure(e.message));
    } catch (e) {
      if (!isClosed) {
        emit(AdminDashboardFailure(e.toString()));
      }
    }
  }
}
