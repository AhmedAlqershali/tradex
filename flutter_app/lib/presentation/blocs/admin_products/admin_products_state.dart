part of 'admin_products_bloc.dart';

abstract class AdminProductsState extends Equatable {
  const AdminProductsState();

  @override
  List<Object?> get props => [];
}

class AdminProductsInitial extends AdminProductsState {
  const AdminProductsInitial();
}

class AdminProductsLoading extends AdminProductsState {
  const AdminProductsLoading({this.previousPage, this.selectedProduct});

  final AdminProductPage? previousPage;
  final Product? selectedProduct;

  @override
  List<Object?> get props => [previousPage, selectedProduct];
}

class AdminProductsLoaded extends AdminProductsState {
  const AdminProductsLoaded({required this.page, this.selectedProduct});

  final AdminProductPage page;
  final Product? selectedProduct;

  @override
  List<Object?> get props => [page, selectedProduct];
}

class AdminProductsFailure extends AdminProductsState {
  const AdminProductsFailure(
    this.message, {
    this.previousPage,
    this.selectedProduct,
  });

  final String message;
  final AdminProductPage? previousPage;
  final Product? selectedProduct;

  @override
  List<Object?> get props => [message, previousPage, selectedProduct];
}
