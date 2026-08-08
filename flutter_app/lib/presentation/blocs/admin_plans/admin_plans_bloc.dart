import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/admin_plan_service.dart';
import 'package:ai_saas/shared/models/admin_plan_model.dart';

part 'admin_plans_event.dart';
part 'admin_plans_state.dart';

class AdminPlansBloc extends Bloc<AdminPlansEvent, AdminPlansState> {
  AdminPlansBloc() : super(const AdminPlansInitial()) {
    on<AdminPlansLoadRequested>(_onLoadRequested);
    on<AdminPlansSearchChanged>(_onSearchChanged);
    on<AdminPlansStatusFilterChanged>(_onStatusFilterChanged);
    on<AdminPlansPageRequested>(_onPageRequested);
    on<AdminPlanDetailsRequested>(_onDetailsRequested);
    on<AdminPlanCreateRequested>(_onCreateRequested);
    on<AdminPlanUpdateRequested>(_onUpdateRequested);
    on<AdminPlanDeleteRequested>(_onDeleteRequested);
  }

  String _search = '';
  String? _status;
  int _page = 1;
  static const _perPage = 20;
  AdminPlan? _selectedPlan;

  Future<void> _onLoadRequested(
    AdminPlansLoadRequested event,
    Emitter<AdminPlansState> emit,
  ) async {
    _page = 1;
    _selectedPlan = null;
    await _fetch(emit);
  }

  Future<void> _onSearchChanged(
    AdminPlansSearchChanged event,
    Emitter<AdminPlansState> emit,
  ) async {
    _search = event.search.trim();
    _page = 1;
    _selectedPlan = null;
    await _fetch(emit);
  }

  Future<void> _onStatusFilterChanged(
    AdminPlansStatusFilterChanged event,
    Emitter<AdminPlansState> emit,
  ) async {
    _status = event.status;
    _page = 1;
    _selectedPlan = null;
    await _fetch(emit);
  }

  Future<void> _onPageRequested(
    AdminPlansPageRequested event,
    Emitter<AdminPlansState> emit,
  ) async {
    _page = event.page;
    _selectedPlan = null;
    await _fetch(emit);
  }

  Future<void> _onDetailsRequested(
    AdminPlanDetailsRequested event,
    Emitter<AdminPlansState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminPlansLoading(
      previousPage: previous,
      selectedPlan: _selectedPlan,
    ));
    try {
      _selectedPlan = await AdminPlanService.instance.getPlan(event.planId);
      if (!isClosed) {
        emit(AdminPlansLoaded(
          page: previous ?? _emptyPage,
          selectedPlan: _selectedPlan,
        ));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _onCreateRequested(
    AdminPlanCreateRequested event,
    Emitter<AdminPlansState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(
        AdminPlansLoading(previousPage: previous, selectedPlan: _selectedPlan));
    try {
      _selectedPlan = await AdminPlanService.instance.createPlan(
        name: event.name,
        displayName: event.displayName,
        monthlyPrice: event.monthlyPrice,
        yearlyPrice: event.yearlyPrice,
        aiUsageLimit: event.aiUsageLimit,
        productLimit: event.productLimit,
        storeLimit: event.storeLimit,
        features: event.features,
        status: event.status,
      );
      await _fetch(emit, keepSelectedPlan: true);
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _onUpdateRequested(
    AdminPlanUpdateRequested event,
    Emitter<AdminPlansState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(
        AdminPlansLoading(previousPage: previous, selectedPlan: _selectedPlan));
    try {
      _selectedPlan = await AdminPlanService.instance.updatePlan(
        id: event.planId,
        name: event.name,
        displayName: event.displayName,
        monthlyPrice: event.monthlyPrice,
        yearlyPrice: event.yearlyPrice,
        aiUsageLimit: event.aiUsageLimit,
        productLimit: event.productLimit,
        storeLimit: event.storeLimit,
        features: event.features,
        status: event.status,
      );
      await _fetch(emit, keepSelectedPlan: true);
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _onDeleteRequested(
    AdminPlanDeleteRequested event,
    Emitter<AdminPlansState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(
        AdminPlansLoading(previousPage: previous, selectedPlan: _selectedPlan));
    try {
      await AdminPlanService.instance.deletePlan(event.planId);
      _selectedPlan = null;
      await _fetch(emit);
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _fetch(
    Emitter<AdminPlansState> emit, {
    bool keepSelectedPlan = false,
  }) async {
    final previous = _pageFromState(state);
    emit(AdminPlansLoading(
      previousPage: previous,
      selectedPlan: keepSelectedPlan ? _selectedPlan : null,
    ));
    try {
      final page = await AdminPlanService.instance.listPlans(
        search: _search,
        status: _status,
        page: _page,
        perPage: _perPage,
      );
      if (!keepSelectedPlan) _selectedPlan = null;
      if (!isClosed) {
        emit(AdminPlansLoaded(page: page, selectedPlan: _selectedPlan));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  void _emitFailure(
    Emitter<AdminPlansState> emit,
    String message,
    AdminPlanPage? previous,
  ) {
    if (!isClosed) {
      emit(AdminPlansFailure(
        message,
        previousPage: previous,
        selectedPlan: _selectedPlan,
      ));
    }
  }

  AdminPlanPage? _pageFromState(AdminPlansState current) {
    if (current is AdminPlansLoaded) return current.page;
    if (current is AdminPlansLoading) return current.previousPage;
    if (current is AdminPlansFailure) return current.previousPage;
    return null;
  }

  static const _emptyPage = AdminPlanPage(
    plans: [],
    pagination: AdminPlanPagination(
      total: 0,
      perPage: _perPage,
      currentPage: 1,
      lastPage: 1,
    ),
  );
}
