import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/cart_service.dart';
import 'package:ai_saas/shared/cart/cart_controller.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartInitial()) {
    on<CartLoadRequested>(_onCartLoadRequested);
    on<CartItemAdded>(_onCartItemAdded);
    on<CartItemQuantityUpdated>(_onCartItemQuantityUpdated);
    on<CartItemRemoved>(_onCartItemRemoved);
    on<CartCleared>(_onCartCleared);
    on<CartLocalItemAdded>(_onCartLocalItemAdded);
    on<CartLocalItemDecremented>(_onCartLocalItemDecremented);
    on<CartLocalItemIncremented>(_onCartLocalItemIncremented);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Returns a [CartLoaded] state built from the current [CartController] state.
  CartLoaded _loadedFromController() {
    final ctrl = CartController.instance;
    return CartLoaded(
      items: List<CartItem>.from(ctrl.items),
      total: ctrl.total,
      itemCount: ctrl.itemCount,
    );
  }

  /// Returns the current items list regardless of state, falling back to empty.
  List<CartItem> _currentItems() {
    final s = state;
    if (s is CartLoaded) return s.items;
    if (s is CartUpdating) return s.items;
    if (s is CartFailure) return s.items;
    return CartController.instance.items;
  }

  String _errorMessage(Object e) {
    if (e is ApiException) return e.message;
    return e.toString();
  }

  // ── Handlers ─────────────────────────────────────────────────────────────────

  Future<void> _onCartLoadRequested(
    CartLoadRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    try {
      // Fetch cart from the server and sync the local controller so that
      // ValueListenableBuilder widgets and _loadedFromController() see the
      // same authoritative data.
      final items = await CartService.instance.getCart();
      CartController.instance.setItems(items);
      emit(_loadedFromController());
    } catch (e) {
      emit(CartFailure(
        message: _errorMessage(e),
        items: CartController.instance.items,
      ));
    }
  }

  Future<void> _onCartItemAdded(
    CartItemAdded event,
    Emitter<CartState> emit,
  ) async {
    final previousItems = _currentItems();
    try {
      final items = await CartService.instance.addItem(
        productId: event.productId,
        quantity: event.quantity,
      );
      CartController.instance.setItems(items);
      emit(_loadedFromController());
    } catch (e) {
      emit(CartFailure(message: _errorMessage(e), items: previousItems));
    }
  }

  Future<void> _onCartItemQuantityUpdated(
    CartItemQuantityUpdated event,
    Emitter<CartState> emit,
  ) async {
    final previousItems = _currentItems();
    try {
      final items = await CartService.instance.updateItem(
        itemId: event.itemId,
        quantity: event.quantity,
      );
      CartController.instance.setItems(items);
      emit(_loadedFromController());
    } catch (e) {
      emit(CartFailure(message: _errorMessage(e), items: previousItems));
    }
  }

  Future<void> _onCartItemRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    final previousItems = _currentItems();
    try {
      final items = await CartService.instance.removeItem(event.itemId);
      CartController.instance.setItems(items);
      emit(_loadedFromController());
    } catch (e) {
      emit(CartFailure(message: _errorMessage(e), items: previousItems));
    }
  }

  Future<void> _onCartCleared(
    CartCleared event,
    Emitter<CartState> emit,
  ) async {
    final previousItems = _currentItems();
    try {
      final items = await CartService.instance.clearCart();
      CartController.instance.setItems(items);
      emit(_loadedFromController());
    } catch (e) {
      emit(CartFailure(message: _errorMessage(e), items: previousItems));
    }
  }

  Future<void> _onCartLocalItemAdded(
    CartLocalItemAdded event,
    Emitter<CartState> emit,
  ) async {
    // Cart persistence is server-owned. Keep this legacy event as a refresh
    // rather than allowing a local-only cart mutation.
    add(const CartLoadRequested());
  }

  Future<void> _onCartLocalItemDecremented(
    CartLocalItemDecremented event,
    Emitter<CartState> emit,
  ) async {
    add(const CartLoadRequested());
  }

  Future<void> _onCartLocalItemIncremented(
    CartLocalItemIncremented event,
    Emitter<CartState> emit,
  ) async {
    add(const CartLoadRequested());
  }
}
