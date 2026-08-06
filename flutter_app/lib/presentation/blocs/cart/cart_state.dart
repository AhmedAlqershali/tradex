part of 'cart_bloc.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any cart operation.
class CartInitial extends CartState {
  const CartInitial();
}

/// A cart operation is in progress (first load or destructive server call).
class CartLoading extends CartState {
  const CartLoading();
}

/// Cart data is available and up-to-date.
class CartLoaded extends CartState {
  const CartLoaded({
    required this.items,
    required this.total,
    required this.itemCount,
  });

  final List<CartItem> items;
  final double total;
  final int itemCount;

  @override
  List<Object?> get props => [items, total, itemCount];
}

/// An optimistic update is being persisted to the server.
/// The UI can render the cart immediately without a loading spinner.
class CartUpdating extends CartState {
  const CartUpdating({
    required this.items,
    required this.total,
    required this.itemCount,
  });

  final List<CartItem> items;
  final double total;
  final int itemCount;

  @override
  List<Object?> get props => [items, total, itemCount];
}

/// A cart operation failed. Preserves the last known cart so the UI stays
/// functional and can show an inline error instead of blanking the screen.
class CartFailure extends CartState {
  const CartFailure({required this.message, required this.items});

  final String message;
  final List<CartItem> items;

  @override
  List<Object?> get props => [message, items];
}
