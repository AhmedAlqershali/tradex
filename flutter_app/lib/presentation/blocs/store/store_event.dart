part of 'store_bloc.dart';

abstract class StoreEvent extends Equatable {
  const StoreEvent();

  @override
  List<Object?> get props => [];
}

class StoresLoadRequested extends StoreEvent {
  const StoresLoadRequested({this.region});

  final String? region;

  @override
  List<Object?> get props => [region];
}

class StoreByIdRequested extends StoreEvent {
  const StoreByIdRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class MyStoreLoadRequested extends StoreEvent {
  const MyStoreLoadRequested();
}

class MyStoreUpdateRequested extends StoreEvent {
  const MyStoreUpdateRequested({
    this.name,
    this.description,
    this.phone,
  });

  final String? name;
  final String? description;
  final String? phone;

  @override
  List<Object?> get props => [name, description, phone];
}

class StoreLogoUploadRequested extends StoreEvent {
  const StoreLogoUploadRequested(this.filePath);

  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

class StoreProductsLoadRequested extends StoreEvent {
  const StoreProductsLoadRequested(this.storeId);

  final String storeId;

  @override
  List<Object?> get props => [storeId];
}
