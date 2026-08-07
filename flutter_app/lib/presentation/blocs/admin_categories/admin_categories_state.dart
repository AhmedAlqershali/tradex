part of 'admin_categories_bloc.dart';

abstract class AdminCategoriesState extends Equatable {
  const AdminCategoriesState();

  @override
  List<Object?> get props => [];
}

class AdminCategoriesInitial extends AdminCategoriesState {
  const AdminCategoriesInitial();
}

class AdminCategoriesLoading extends AdminCategoriesState {
  const AdminCategoriesLoading({
    this.previousPage,
    this.selectedCategory,
  });

  final AdminCategoryPage? previousPage;
  final AdminCategory? selectedCategory;

  @override
  List<Object?> get props => [previousPage, selectedCategory];
}

class AdminCategoriesLoaded extends AdminCategoriesState {
  const AdminCategoriesLoaded({
    required this.page,
    this.selectedCategory,
  });

  final AdminCategoryPage page;
  final AdminCategory? selectedCategory;

  @override
  List<Object?> get props => [page, selectedCategory];
}

class AdminCategoriesFailure extends AdminCategoriesState {
  const AdminCategoriesFailure(
    this.message, {
    this.previousPage,
    this.selectedCategory,
  });

  final String message;
  final AdminCategoryPage? previousPage;
  final AdminCategory? selectedCategory;

  @override
  List<Object?> get props => [message, previousPage, selectedCategory];
}
