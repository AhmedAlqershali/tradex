import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/merchant_dashboard_service.dart';
import 'package:ai_saas/shared/models/merchant_dashboard_model.dart';

part 'merchant_dashboard_event.dart';
part 'merchant_dashboard_state.dart';

class MerchantDashboardBloc
    extends Bloc<MerchantDashboardEvent, MerchantDashboardState> {
  MerchantDashboardBloc({
    Future<MerchantDashboardModel> Function()? loadDashboard,
  })  : _loadDashboard =
            loadDashboard ?? MerchantDashboardService.instance.getDashboard,
        super(const MerchantDashboardInitial()) {
    on<MerchantDashboardLoadRequested>(_onLoadRequested);
  }

  final Future<MerchantDashboardModel> Function() _loadDashboard;

  Future<void> _onLoadRequested(
    MerchantDashboardLoadRequested event,
    Emitter<MerchantDashboardState> emit,
  ) async {
    emit(const MerchantDashboardLoading());
    try {
      final dashboard = await _loadDashboard();
      if (!isClosed) emit(MerchantDashboardLoaded(dashboard));
    } on ApiException catch (e) {
      if (!isClosed) emit(MerchantDashboardFailure(e.message));
    } catch (e) {
      if (!isClosed) emit(MerchantDashboardFailure(e.toString()));
    }
  }
}