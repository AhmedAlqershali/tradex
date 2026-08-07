part of 'admin_categories_bloc.dart';

abstract class AdminCategoriesEvent extends Equatable {
  const AdminCategoriesEvent();

  @override
  List<Object?> get props => [];
}

class AdminCategoriesLoadRequested extends AdminCategoriesEvent {
  const AdminCategoriesLoadRequested();
}

class AdminCategoriesSearchChanged extends AdminCategoriesEvent {
  const AdminCategoriesSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

class AdminCategoriesStatusFilterChanged extends AdminCategoriesEvent {
  const AdminCategoriesStatusFilterChanged(this.status);

  final String? status;

  @override
  List<Object?> get props => [status];
}

class AdminCategoriesPageRequested extends AdminCategoriesEvent {
  const AdminCategoriesPageRequested(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

class AdminCategoryDetailsRequested extends AdminCategoriesEvent {
  const AdminCategoryDetailsRequested(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}

class AdminCategoryCreateRequested extends AdminCategoriesEvent {
  const AdminCategoryCreateRequested({
    required this.name,
    required this.status,
    this.imagePath,
  });

  final String name;
  final String status;
  final String? imagePath;

  @override
  List<Object?> get props => [name, status, imagePath];
}

class AdminCategoryUpdateRequested extends AdminCategoriesEvent {
  const AdminCategoryUpdateRequested({
    required this.categoryId,
    this.name,
    this.status,
    this.imagePath,
  });

  final String categoryId;
  final String? name;
  final String? status;
  final String? imagePath;

  @override
  List<Object?> get props => [categoryId, name, status, imagePath];
}

class AdminCategoryDeleteRequested extends AdminCategoriesEvent {
  const AdminCategoryDeleteRequested(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}
