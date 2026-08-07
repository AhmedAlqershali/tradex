import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/admin_category_service.dart';
import 'package:ai_saas/shared/models/admin_category_model.dart';

part 'admin_categories_event.dart';
part 'admin_categories_state.dart';

class AdminCategoriesBloc
    extends Bloc<AdminCategoriesEvent, AdminCategoriesState> {
  AdminCategoriesBloc() : super(const AdminCategoriesInitial()) {
    on<AdminCategoriesLoadRequested>(_onLoadRequested);
    on<AdminCategoriesSearchChanged>(_onSearchChanged);
    on<AdminCategoriesStatusFilterChanged>(_onStatusFilterChanged);
    on<AdminCategoriesPageRequested>(_onPageRequested);
    on<AdminCategoryDetailsRequested>(_onDetailsRequested);
    on<AdminCategoryCreateRequested>(_onCreateRequested);
    on<AdminCategoryUpdateRequested>(_onUpdateRequested);
    on<AdminCategoryDeleteRequested>(_onDeleteRequested);
  }

  String _search = '';
  String? _status;
  int _page = 1;
  static const _perPage = 20;
  AdminCategory? _selectedCategory;

  Future<void> _onLoadRequested(
    AdminCategoriesLoadRequested event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    _page = 1;
    _selectedCategory = null;
    await _fetch(emit);
  }

  Future<void> _onSearchChanged(
    AdminCategoriesSearchChanged event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    _search = event.search.trim();
    _page = 1;
    _selectedCategory = null;
    await _fetch(emit);
  }

  Future<void> _onStatusFilterChanged(
    AdminCategoriesStatusFilterChanged event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    _status = event.status;
    _page = 1;
    _selectedCategory = null;
    await _fetch(emit);
  }

  Future<void> _onPageRequested(
    AdminCategoriesPageRequested event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    _page = event.page;
    _selectedCategory = null;
    await _fetch(emit);
  }

  Future<void> _onDetailsRequested(
    AdminCategoryDetailsRequested event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminCategoriesLoading(
      previousPage: previous,
      selectedCategory: _selectedCategory,
    ));
    try {
      _selectedCategory =
          await AdminCategoryService.instance.getCategory(event.categoryId);
      if (!isClosed) {
        emit(AdminCategoriesLoaded(
          page: previous ?? _emptyPage,
          selectedCategory: _selectedCategory,
        ));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _onCreateRequested(
    AdminCategoryCreateRequested event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminCategoriesLoading(
      previousPage: previous,
      selectedCategory: _selectedCategory,
    ));
    try {
      _selectedCategory = await AdminCategoryService.instance.createCategory(
        name: event.name,
        status: event.status,
        imagePath: event.imagePath,
      );
      await _fetch(emit, keepSelectedCategory: true);
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _onUpdateRequested(
    AdminCategoryUpdateRequested event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminCategoriesLoading(
      previousPage: previous,
      selectedCategory: _selectedCategory,
    ));
    try {
      _selectedCategory = await AdminCategoryService.instance.updateCategory(
        id: event.categoryId,
        name: event.name,
        status: event.status,
        imagePath: event.imagePath,
      );
      await _fetch(emit, keepSelectedCategory: true);
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _onDeleteRequested(
    AdminCategoryDeleteRequested event,
    Emitter<AdminCategoriesState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminCategoriesLoading(
      previousPage: previous,
      selectedCategory: _selectedCategory,
    ));
    try {
      await AdminCategoryService.instance.deleteCategory(event.categoryId);
      _selectedCategory = null;
      await _fetch(emit);
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _fetch(
    Emitter<AdminCategoriesState> emit, {
    bool keepSelectedCategory = false,
  }) async {
    final previous = _pageFromState(state);
    emit(AdminCategoriesLoading(
      previousPage: previous,
      selectedCategory: _selectedCategory,
    ));
    try {
      final page = await AdminCategoryService.instance.listCategories(
        search: _search,
        status: _status,
        page: _page,
        perPage: _perPage,
      );
      if (!isClosed) {
        emit(AdminCategoriesLoaded(
          page: page,
          selectedCategory: keepSelectedCategory ? _selectedCategory : null,
        ));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  void _emitFailure(
    Emitter<AdminCategoriesState> emit,
    String message,
    AdminCategoryPage? previous,
  ) {
    if (!isClosed) {
      emit(AdminCategoriesFailure(
        message,
        previousPage: previous,
        selectedCategory: _selectedCategory,
      ));
    }
  }

  AdminCategoryPage? _pageFromState(AdminCategoriesState current) {
    if (current is AdminCategoriesLoaded) return current.page;
    if (current is AdminCategoriesLoading) return current.previousPage;
    if (current is AdminCategoriesFailure) return current.previousPage;
    return null;
  }

  static const _emptyPage = AdminCategoryPage(
    categories: [],
    pagination: AdminCategoryPagination(
      total: 0,
      perPage: _perPage,
      currentPage: 1,
      lastPage: 1,
    ),
  );
}
