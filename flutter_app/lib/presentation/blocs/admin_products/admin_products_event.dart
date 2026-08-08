part of 'admin_products_bloc.dart';

abstract class AdminProductsEvent extends Equatable {
  const AdminProductsEvent();

  @override
  List<Object?> get props => [];
}

class AdminProductsLoadRequested extends AdminProductsEvent {
  const AdminProductsLoadRequested();
}

class AdminProductsSearchChanged extends AdminProductsEvent {
  const AdminProductsSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

class AdminProductsStatusChanged extends AdminProductsEvent {
  const AdminProductsStatusChanged(this.status);

  final String? status;

  @override
  List<Object?> get props => [status];
}

class AdminProductsPageRequested extends AdminProductsEvent {
  const AdminProductsPageRequested(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

class AdminProductDetailsRequested extends AdminProductsEvent {
  const AdminProductDetailsRequested(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}
