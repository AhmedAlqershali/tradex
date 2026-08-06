part of 'store_bloc.dart';

abstract class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object?> get props => [];
}

class StoreInitial extends StoreState {
  const StoreInitial();
}

class StoreLoading extends StoreState {
  const StoreLoading();
}

class StoresLoaded extends StoreState {
  const StoresLoaded(this.stores);

  final List<StoreModel> stores;

  @override
  List<Object?> get props => [stores];
}

class StoreDetailLoaded extends StoreState {
  const StoreDetailLoaded(this.store);

  final StoreModel store;

  @override
  List<Object?> get props => [store];
}

class MyStoreLoaded extends StoreState {
  const MyStoreLoaded(this.store);

  final StoreModel store;

  @override
  List<Object?> get props => [store];
}

class StoreProductsLoaded extends StoreState {
  const StoreProductsLoaded(this.products, this.storeId);

  final List<Product> products;
  final String storeId;

  @override
  List<Object?> get props => [products, storeId];
}

class StoreUpdated extends StoreState {
  const StoreUpdated(this.store);

  final StoreModel store;

  @override
  List<Object?> get props => [store];
}

class StoreFailure extends StoreState {
  const StoreFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
