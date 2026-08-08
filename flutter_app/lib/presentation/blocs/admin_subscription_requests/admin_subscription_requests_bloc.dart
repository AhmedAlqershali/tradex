import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:typed_data';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/admin_subscription_request_service.dart';
import 'package:ai_saas/shared/models/admin_subscription_request_model.dart';

part 'admin_subscription_requests_event.dart';
part 'admin_subscription_requests_state.dart';

class AdminSubscriptionRequestsBloc extends Bloc<
    AdminSubscriptionRequestsEvent, AdminSubscriptionRequestsState> {
  AdminSubscriptionRequestsBloc()
      : super(const AdminSubscriptionRequestsInitial()) {
    on<AdminSubscriptionRequestsLoadRequested>(_onLoadRequested);
    on<AdminSubscriptionRequestsStatusChanged>(_onStatusChanged);
    on<AdminSubscriptionRequestsPageRequested>(_onPageRequested);
    on<AdminSubscriptionRequestDetailsRequested>(_onDetailsRequested);
    on<AdminSubscriptionRequestProofRequested>(_onProofRequested);
    on<AdminSubscriptionRequestApproveRequested>(_onApproveRequested);
    on<AdminSubscriptionRequestRejectRequested>(_onRejectRequested);
  }

  static const _perPage = 15;
  int _page = 1;
  String? _status;
  AdminSubscriptionRequest? _selectedRequest;
  Uint8List? _proofBytes;

  Future<void> _onLoadRequested(
    AdminSubscriptionRequestsLoadRequested event,
    Emitter<AdminSubscriptionRequestsState> emit,
  ) async {
    _page = 1;
    _status = null;
    _selectedRequest = null;
    _proofBytes = null;
    await _fetch(emit);
  }

  Future<void> _onStatusChanged(
    AdminSubscriptionRequestsStatusChanged event,
    Emitter<AdminSubscriptionRequestsState> emit,
  ) async {
    _page = 1;
    _status = event.status;
    _selectedRequest = null;
    _proofBytes = null;
    await _fetch(emit);
  }

  Future<void> _onPageRequested(
    AdminSubscriptionRequestsPageRequested event,
    Emitter<AdminSubscriptionRequestsState> emit,
  ) async {
    _page = event.page;
    await _fetch(emit);
  }

  Future<void> _onDetailsRequested(
    AdminSubscriptionRequestDetailsRequested event,
    Emitter<AdminSubscriptionRequestsState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminSubscriptionRequestsLoading(
      previousPage: previous,
      selectedRequest: _selectedRequest,
      proofBytes: _proofBytes,
    ));
    try {
      _selectedRequest =
          await AdminSubscriptionRequestService.instance.getRequest(event.id);
      if (!isClosed) {
        emit(AdminSubscriptionRequestsLoaded(
          page: previous ?? _emptyPage,
          selectedRequest: _selectedRequest,
          proofBytes: null,
        ));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _onProofRequested(
    AdminSubscriptionRequestProofRequested event,
    Emitter<AdminSubscriptionRequestsState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminSubscriptionRequestsLoading(
      previousPage: previous,
      selectedRequest: _selectedRequest,
      proofBytes: _proofBytes,
    ));
    try {
      _proofBytes = await AdminSubscriptionRequestService.instance
          .downloadProof(event.id);
      if (!isClosed) {
        emit(AdminSubscriptionRequestsLoaded(
          page: previous ?? _emptyPage,
          selectedRequest: _selectedRequest,
          proofBytes: _proofBytes,
        ));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _onApproveRequested(
    AdminSubscriptionRequestApproveRequested event,
    Emitter<AdminSubscriptionRequestsState> emit,
  ) async {
    await _review(
      emit,
      () => AdminSubscriptionRequestService.instance.approve(event.id),
    );
  }

  Future<void> _onRejectRequested(
    AdminSubscriptionRequestRejectRequested event,
    Emitter<AdminSubscriptionRequestsState> emit,
  ) async {
    await _review(
      emit,
      () => AdminSubscriptionRequestService.instance.reject(
        event.id,
        event.reason,
      ),
    );
  }

  Future<void> _review(
    Emitter<AdminSubscriptionRequestsState> emit,
    Future<AdminSubscriptionRequest> Function() action,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminSubscriptionRequestsLoading(
      previousPage: previous,
      selectedRequest: _selectedRequest,
      proofBytes: _proofBytes,
    ));
    try {
      _selectedRequest = await action();
      await _fetch(emit, keepSelectedRequest: true);
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _fetch(
    Emitter<AdminSubscriptionRequestsState> emit, {
    bool keepSelectedRequest = false,
  }) async {
    final previous = _pageFromState(state);
    if (!keepSelectedRequest) _selectedRequest = null;
    if (!keepSelectedRequest) _proofBytes = null;
    emit(AdminSubscriptionRequestsLoading(
      previousPage: previous,
      selectedRequest: _selectedRequest,
      proofBytes: _proofBytes,
    ));
    try {
      final page = await AdminSubscriptionRequestService.instance.listRequests(
        status: _status,
        page: _page,
        perPage: _perPage,
      );
      if (!isClosed) {
        emit(AdminSubscriptionRequestsLoaded(
          page: page,
          selectedRequest: _selectedRequest,
          proofBytes: _proofBytes,
        ));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  AdminSubscriptionRequestPage? _pageFromState(
    AdminSubscriptionRequestsState current,
  ) {
    if (current is AdminSubscriptionRequestsLoaded) return current.page;
    if (current is AdminSubscriptionRequestsLoading) return current.previousPage;
    if (current is AdminSubscriptionRequestsFailure) return current.previousPage;
    return null;
  }

  void _emitFailure(
    Emitter<AdminSubscriptionRequestsState> emit,
    String message,
    AdminSubscriptionRequestPage? previous,
  ) {
    if (!isClosed) {
      emit(AdminSubscriptionRequestsFailure(
        message,
        previousPage: previous,
        selectedRequest: _selectedRequest,
        proofBytes: _proofBytes,
      ));
    }
  }

  AdminSubscriptionRequestPage get _emptyPage =>
      const AdminSubscriptionRequestPage(
        requests: [],
        pagination: AdminSubscriptionRequestPagination(
          total: 0,
          perPage: _perPage,
          currentPage: 1,
          lastPage: 1,
        ),
      );
}