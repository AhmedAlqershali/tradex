part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

/// Requests loading the product/store category list (GET /config/categories).
class CategoryListRequested extends CategoryEvent {
  const CategoryListRequested();
}

/// Requests loading the city/region list (GET /config/cities).
class CityListRequested extends CategoryEvent {
  const CityListRequested();
}
