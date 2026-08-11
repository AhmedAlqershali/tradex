import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/category_service.dart';

part 'category_event.dart';
part 'category_state.dart';

/// Provides lists of product categories and city/region strings from the
/// backend config endpoints:
///   GET /config/categories
///   GET /config/cities
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(const CategoryInitial()) {
    on<CategoryListRequested>(_onCategoriesLoadRequested);
    on<CityListRequested>(_onCitiesLoadRequested);
  }

  Future<void> _onCategoriesLoadRequested(
    CategoryListRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading());
    try {
      final options = await CategoryService.instance.getCategoryOptions();
      if (!isClosed) {
        emit(CategoriesLoaded(
          options.map((option) => option.name).toList(),
          options: options,
        ));
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(CategoryFailure(e.message));
    } catch (e) {
      if (!isClosed) emit(CategoryFailure(e.toString()));
    }
  }

  Future<void> _onCitiesLoadRequested(
    CityListRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading());
    try {
      final cities = await CategoryService.instance.getCities();
      if (!isClosed) emit(CitiesLoaded(cities));
    } on ApiException catch (e) {
      if (!isClosed) emit(CategoryFailure(e.message));
    } catch (e) {
      if (!isClosed) emit(CategoryFailure(e.toString()));
    }
  }
}
