import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/admin_product_service.dart';
import 'package:ai_saas/shared/models/admin_product_model.dart';
import 'package:ai_saas/shared/models/product_model.dart';

part 'admin_products_event.dart';
part 'admin_products_state.dart';

class AdminProductsBloc extends Bloc<AdminProductsEvent, AdminProductsState> {
  AdminProductsBloc() : super(const AdminProductsInitial()) {
    on<AdminProductsLoadRequested>(_onLoadRequested);
    on<AdminProductsSearchChanged>(_onSearchChanged);
    on<AdminProductsStatusChanged>(_onStatusChanged);
    on<AdminProductsPageRequested>(_onPageRequested);
    on<AdminProductDetailsRequested>(_onDetailsRequested);
  }

  String _search = '';
  String? _status;
  int _page = 1;
  static const _perPage = 15;
  Product? _selectedProduct;

  Future<void> _onLoadRequested(
    AdminProductsLoadRequested event,
    Emitter<AdminProductsState> emit,
  ) async {
    _page = 1;
    _selectedProduct = null;
    await _fetch(emit);
  }

  Future<void> _onSearchChanged(
    AdminProductsSearchChanged event,
    Emitter<AdminProductsState> emit,
  ) async {
    _search = event.search.trim();
    _page = 1;
    await _fetch(emit);
  }

  Future<void> _onStatusChanged(
    AdminProductsStatusChanged event,
    Emitter<AdminProductsState> emit,
  ) async {
    _status = event.status;
    _page = 1;
    await _fetch(emit);
  }

  Future<void> _onPageRequested(
    AdminProductsPageRequested event,
    Emitter<AdminProductsState> emit,
  ) async {
    _page = event.page;
    await _fetch(emit);
  }

  Future<void> _onDetailsRequested(
    AdminProductDetailsRequested event,
    Emitter<AdminProductsState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminProductsLoading(
      previousPage: previous,
      selectedProduct: _selectedProduct,
    ));
    try {
      _selectedProduct =
          await AdminProductService.instance.getProduct(event.productId);
      if (!isClosed) {
        emit(AdminProductsLoaded(
          page: previous ?? _emptyPage,
          selectedProduct: _selectedProduct,
        ));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _fetch(Emitter<AdminProductsState> emit) async {
    final previous = _pageFromState(state);
    emit(AdminProductsLoading(
      previousPage: previous,
      selectedProduct: _selectedProduct,
    ));
    try {
      final page = await AdminProductService.instance.listProducts(
        search: _search,
        status: _status,
        page: _page,
        perPage: _perPage,
      );
      if (!isClosed) {
        emit(AdminProductsLoaded(
          page: page,
          selectedProduct: _selectedProduct,
        ));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  void _emitFailure(
    Emitter<AdminProductsState> emit,
    String message,
    AdminProductPage? previous,
  ) {
    if (!isClosed) {
      emit(AdminProductsFailure(
        message,
        previousPage: previous,
        selectedProduct: _selectedProduct,
      ));
    }
  }

  AdminProductPage? _pageFromState(AdminProductsState value) {
    if (value is AdminProductsLoaded) return value.page;
    if (value is AdminProductsLoading) return value.previousPage;
    if (value is AdminProductsFailure) return value.previousPage;
    return null;
  }

  AdminProductPage get _emptyPage => const AdminProductPage(
        products: [],
        pagination: AdminProductPagination(
          total: 0,
          perPage: _perPage,
          currentPage: 1,
          lastPage: 1,
        ),
      );
}
