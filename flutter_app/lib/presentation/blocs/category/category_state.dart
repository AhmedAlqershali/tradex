part of 'category_bloc.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

class CategoriesLoaded extends CategoryState {
  const CategoriesLoaded(this.categories, {this.options = const []});

  final List<String> categories;
  final List<CategoryOption> options;

  @override
  List<Object?> get props => [categories, options];
}

class CitiesLoaded extends CategoryState {
  const CitiesLoaded(this.cities);

  final List<String> cities;

  @override
  List<Object?> get props => [cities];
}

class CategoryFailure extends CategoryState {
  const CategoryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
