import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/admin_merchant_service.dart';
import 'package:ai_saas/shared/models/admin_merchant_model.dart';

part 'admin_merchants_event.dart';
part 'admin_merchants_state.dart';

typedef AdminMerchantListLoader = Future<AdminMerchantPage> Function({
  String? search,
  String? status,
  int page,
  int perPage,
});

typedef AdminMerchantDetailsLoader = Future<AdminMerchant> Function(String id);
typedef AdminMerchantStatusUpdater = Future<AdminMerchant> Function(
  String id,
  String status,
);

class AdminMerchantsBloc
    extends Bloc<AdminMerchantsEvent, AdminMerchantsState> {
  AdminMerchantsBloc({
    AdminMerchantListLoader? listMerchants,
    AdminMerchantDetailsLoader? getMerchant,
    AdminMerchantStatusUpdater? updateStatus,
  })  : _listMerchants =
            listMerchants ?? AdminMerchantService.instance.listMerchants,
        _getMerchant = getMerchant ?? AdminMerchantService.instance.getMerchant,
        _updateStatus =
            updateStatus ?? AdminMerchantService.instance.updateStatus,
        super(const AdminMerchantsInitial()) {
    on<AdminMerchantsLoadRequested>(_onLoadRequested);
    on<AdminMerchantsSearchChanged>(_onSearchChanged);
    on<AdminMerchantsStatusFilterChanged>(_onStatusFilterChanged);
    on<AdminMerchantsPageRequested>(_onPageRequested);
    on<AdminMerchantDetailsRequested>(_onDetailsRequested);
    on<AdminMerchantStatusUpdateRequested>(_onStatusUpdateRequested);
  }

  final AdminMerchantListLoader _listMerchants;
  final AdminMerchantDetailsLoader _getMerchant;
  final AdminMerchantStatusUpdater _updateStatus;

  String _search = '';
  String? _status;
  int _page = 1;
  static const _perPage = 15;
  AdminMerchant? _selectedMerchant;

  Future<void> _onLoadRequested(
    AdminMerchantsLoadRequested event,
    Emitter<AdminMerchantsState> emit,
  ) async {
    _page = 1;
    _selectedMerchant = null;
    await _fetch(emit);
  }

  Future<void> _onSearchChanged(
    AdminMerchantsSearchChanged event,
    Emitter<AdminMerchantsState> emit,
  ) async {
    _search = event.search.trim();
    _page = 1;
    _selectedMerchant = null;
    await _fetch(emit);
  }

  Future<void> _onStatusFilterChanged(
    AdminMerchantsStatusFilterChanged event,
    Emitter<AdminMerchantsState> emit,
  ) async {
    _status = event.status;
    _page = 1;
    _selectedMerchant = null;
    await _fetch(emit);
  }

  Future<void> _onPageRequested(
    AdminMerchantsPageRequested event,
    Emitter<AdminMerchantsState> emit,
  ) async {
    _page = event.page;
    _selectedMerchant = null;
    await _fetch(emit);
  }

  Future<void> _onDetailsRequested(
    AdminMerchantDetailsRequested event,
    Emitter<AdminMerchantsState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminMerchantsLoading(
      previousPage: previous,
      selectedMerchant: _selectedMerchant,
    ));
    try {
      _selectedMerchant = await _getMerchant(event.merchantId);
      if (!isClosed) {
        emit(AdminMerchantsLoaded(
          page: previous ?? _emptyPage,
          selectedMerchant: _selectedMerchant,
        ));
      }
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(AdminMerchantsFailure(
          e.message,
          previousPage: previous,
          selectedMerchant: _selectedMerchant,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminMerchantsFailure(
          e.toString(),
          previousPage: previous,
          selectedMerchant: _selectedMerchant,
        ));
      }
    }
  }

  Future<void> _onStatusUpdateRequested(
    AdminMerchantStatusUpdateRequested event,
    Emitter<AdminMerchantsState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminMerchantsLoading(
      previousPage: previous,
      selectedMerchant: _selectedMerchant,
    ));
    try {
      _selectedMerchant = await _updateStatus(event.merchantId, event.status);
      await _fetch(emit, keepSelectedMerchant: true);
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(AdminMerchantsFailure(
          e.message,
          previousPage: previous,
          selectedMerchant: _selectedMerchant,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminMerchantsFailure(
          e.toString(),
          previousPage: previous,
          selectedMerchant: _selectedMerchant,
        ));
      }
    }
  }

  Future<void> _fetch(
    Emitter<AdminMerchantsState> emit, {
    bool keepSelectedMerchant = false,
  }) async {
    final previous = _pageFromState(state);
    emit(AdminMerchantsLoading(
      previousPage: previous,
      selectedMerchant: keepSelectedMerchant ? _selectedMerchant : null,
    ));
    try {
      final page = await _listMerchants(
        search: _search,
        status: _status,
        page: _page,
        perPage: _perPage,
      );
      if (!keepSelectedMerchant) _selectedMerchant = null;
      if (!isClosed) {
        emit(AdminMerchantsLoaded(
          page: page,
          selectedMerchant: _selectedMerchant,
        ));
      }
    } on ApiException catch (e) {
      if (!isClosed) {
        emit(AdminMerchantsFailure(
          e.message,
          previousPage: previous,
          selectedMerchant: _selectedMerchant,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AdminMerchantsFailure(
          e.toString(),
          previousPage: previous,
          selectedMerchant: _selectedMerchant,
        ));
      }
    }
  }

  AdminMerchantPage? _pageFromState(AdminMerchantsState current) {
    if (current is AdminMerchantsLoaded) return current.page;
    if (current is AdminMerchantsLoading) return current.previousPage;
    if (current is AdminMerchantsFailure) return current.previousPage;
    return null;
  }

  static const _emptyPage = AdminMerchantPage(
    merchants: [],
    pagination: AdminMerchantPagination(
      total: 0,
      perPage: _perPage,
      currentPage: 1,
      lastPage: 1,
    ),
  );
}
