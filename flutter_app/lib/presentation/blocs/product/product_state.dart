part of 'product_bloc.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductLoading extends ProductState {
  const ProductLoading();
}

class ProductsLoaded extends ProductState {
  const ProductsLoaded(this.products);

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

class ProductDetailLoaded extends ProductState {
  const ProductDetailLoaded(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

class ProductSearchResult extends ProductState {
  const ProductSearchResult(this.results, this.query);

  final List<Product> results;
  final String query;

  @override
  List<Object?> get props => [results, query];
}

class UnifiedSearchResultState extends ProductState {
  const UnifiedSearchResultState(this.products, this.stores, this.query);

  final List<Product> products;
  final List<StoreModel> stores;
  final String query;

  @override
  List<Object?> get props => [products, stores, query];
}

class ProductCreated extends ProductState {
  const ProductCreated(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

class ProductUpdated extends ProductState {
  const ProductUpdated(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

class ProductDeleted extends ProductState {
  const ProductDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Product-specific categories loaded state.
/// Renamed from [CategoriesLoaded] to avoid collision with the identically
/// named state emitted by [CategoryBloc].
class ProductCategoriesLoaded extends ProductState {
  const ProductCategoriesLoaded(this.categories);

  final List<String> categories;

  @override
  List<Object?> get props => [categories];
}

class ProductFailure extends ProductState {
  const ProductFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
