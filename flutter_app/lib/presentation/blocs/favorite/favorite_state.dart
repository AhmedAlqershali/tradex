part of 'favorite_bloc.dart';

abstract class FavoriteState extends Equatable {
  const FavoriteState();

  @override
  List<Object?> get props => [];
}

class FavoriteInitial extends FavoriteState {
  const FavoriteInitial();
}

class FavoriteLoading extends FavoriteState {
  const FavoriteLoading();
}

class FavoriteLoaded extends FavoriteState {
  const FavoriteLoaded(this.products);

  final List<Product> products;

  bool isFavorite(String productId) =>
      products.any((p) => p.id == productId);

  @override
  List<Object?> get props => [products];
}

class FavoriteFailure extends FavoriteState {
  const FavoriteFailure({required this.message, this.products = const []});

  final String message;

  /// Last known favorites so the UI does not blank on a transient error.
  final List<Product> products;

  @override
  List<Object?> get props => [message, products];
}
