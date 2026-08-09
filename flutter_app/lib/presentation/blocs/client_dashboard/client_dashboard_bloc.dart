import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/client_dashboard_service.dart';
import 'package:ai_saas/shared/models/client_dashboard_model.dart';

part 'client_dashboard_event.dart';
part 'client_dashboard_state.dart';

class ClientDashboardBloc
    extends Bloc<ClientDashboardEvent, ClientDashboardState> {
  ClientDashboardBloc({
    Future<ClientDashboardModel> Function()? loadDashboard,
  })  : _loadDashboard =
            loadDashboard ?? ClientDashboardService.instance.getDashboard,
        super(const ClientDashboardInitial()) {
    on<ClientDashboardLoadRequested>(_onLoadRequested);
  }

  final Future<ClientDashboardModel> Function() _loadDashboard;

  Future<void> _onLoadRequested(
    ClientDashboardLoadRequested event,
    Emitter<ClientDashboardState> emit,
  ) async {
    emit(const ClientDashboardLoading());
    try {
      final dashboard = await _loadDashboard();
      if (!isClosed) emit(ClientDashboardLoaded(dashboard));
    } on ApiException catch (e) {
      if (!isClosed) emit(ClientDashboardFailure(e.message));
    } catch (e) {
      if (!isClosed) emit(ClientDashboardFailure(e.toString()));
    }
  }
}
