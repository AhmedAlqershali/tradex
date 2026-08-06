part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Requests a fresh cart load from the server.
class CartLoadRequested extends CartEvent {
  const CartLoadRequested();
}

/// Requests adding a product item to the server cart.
class CartItemAdded extends CartEvent {
  const CartItemAdded({required this.productId, required this.quantity});

  final String productId;
  final int quantity;

  @override
  List<Object?> get props => [productId, quantity];
}

/// Requests updating the quantity of an existing cart item on the server.
class CartItemQuantityUpdated extends CartEvent {
  const CartItemQuantityUpdated({required this.itemId, required this.quantity});

  final String itemId;
  final int quantity;

  @override
  List<Object?> get props => [itemId, quantity];
}

/// Requests removing an item from the server cart.
class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

/// Requests clearing all items from the server cart.
class CartCleared extends CartEvent {
  const CartCleared();
}

/// Optimistically adds a [CartItem] to the local cart (no server round-trip).
class CartLocalItemAdded extends CartEvent {
  const CartLocalItemAdded(this.item);

  final CartItem item;

  @override
  List<Object?> get props => [item];
}

/// Optimistically decrements the quantity of a local cart item.
/// Removes the item if quantity reaches zero.
class CartLocalItemDecremented extends CartEvent {
  const CartLocalItemDecremented(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

/// Optimistically increments the quantity of a local cart item.
class CartLocalItemIncremented extends CartEvent {
  const CartLocalItemIncremented(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}
