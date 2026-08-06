part of 'favorite_bloc.dart';

abstract class FavoriteEvent extends Equatable {
  const FavoriteEvent();

  @override
  List<Object?> get props => [];
}

/// Load the authenticated user's favorites from the server.
class FavoritesLoadRequested extends FavoriteEvent {
  const FavoritesLoadRequested();
}

/// Add a product to favorites.
class FavoriteAddRequested extends FavoriteEvent {
  const FavoriteAddRequested(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

/// Remove a product from favorites.
class FavoriteRemoveRequested extends FavoriteEvent {
  const FavoriteRemoveRequested(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

/// Toggle a product's favorite status.
class FavoriteToggleRequested extends FavoriteEvent {
  const FavoriteToggleRequested(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}
