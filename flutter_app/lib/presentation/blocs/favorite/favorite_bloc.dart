import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/favorite_service.dart';
import 'package:ai_saas/shared/favorites/favorite_controller.dart';
import 'package:ai_saas/shared/models/product_model.dart';

part 'favorite_event.dart';
part 'favorite_state.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  FavoriteBloc() : super(const FavoriteInitial()) {
    on<FavoritesLoadRequested>(_onFavoritesLoadRequested);
    on<FavoriteAddRequested>(_onFavoriteAddRequested);
    on<FavoriteRemoveRequested>(_onFavoriteRemoveRequested);
    on<FavoriteToggleRequested>(_onFavoriteToggleRequested);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<Product> _currentProducts() {
    final s = state;
    if (s is FavoriteLoaded) return s.products;
    if (s is FavoriteFailure) return s.products;
    return FavoriteController.instance.favorites;
  }

  String _errorMessage(Object e) {
    if (e is ApiException) return e.message;
    return e.toString();
  }

  // ── Load ─────────────────────────────────────────────────────────────────────

  Future<void> _onFavoritesLoadRequested(
    FavoritesLoadRequested event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(const FavoriteLoading());
    try {
      final products = await FavoriteService.instance.getFavorites();
      // Sync local controller so legacy ValueListenableBuilder widgets still work.
      FavoriteController.instance.clear();
      for (final p in products) {
        FavoriteController.instance.addFavorite(p);
      }
      emit(FavoriteLoaded(products));
    } catch (e) {
      // Fall back to local controller state on network failure.
      emit(FavoriteFailure(
        message: _errorMessage(e),
        products: FavoriteController.instance.favorites,
      ));
    }
  }

  // ── Add ──────────────────────────────────────────────────────────────────────

  Future<void> _onFavoriteAddRequested(
    FavoriteAddRequested event,
    Emitter<FavoriteState> emit,
  ) async {
    final previous = _currentProducts();
    // Optimistic update.
    FavoriteController.instance.addFavorite(event.product);
    final optimistic = List<Product>.from(FavoriteController.instance.favorites);
    emit(FavoriteLoaded(optimistic));
    try {
      await FavoriteService.instance.addFavorite(event.product.id);
    } catch (e) {
      // Rollback optimistic update on failure.
      FavoriteController.instance.removeFavorite(event.product.id);
      emit(FavoriteFailure(message: _errorMessage(e), products: previous));
    }
  }

  // ── Remove ───────────────────────────────────────────────────────────────────

  Future<void> _onFavoriteRemoveRequested(
    FavoriteRemoveRequested event,
    Emitter<FavoriteState> emit,
  ) async {
    final previous = _currentProducts();
    // Optimistic update.
    FavoriteController.instance.removeFavorite(event.productId);
    final optimistic = List<Product>.from(FavoriteController.instance.favorites);
    emit(FavoriteLoaded(optimistic));
    try {
      await FavoriteService.instance.removeFavorite(event.productId);
    } catch (e) {
      // Rollback: re-add the product from previous list.
      final removed = previous.firstWhere(
        (p) => p.id == event.productId,
        orElse: () => previous.first,
      );
      FavoriteController.instance.addFavorite(removed);
      emit(FavoriteFailure(message: _errorMessage(e), products: previous));
    }
  }

  // ── Toggle ───────────────────────────────────────────────────────────────────

  Future<void> _onFavoriteToggleRequested(
    FavoriteToggleRequested event,
    Emitter<FavoriteState> emit,
  ) async {
    final isFav = FavoriteController.instance.isFavorite(event.product.id);
    if (isFav) {
      add(FavoriteRemoveRequested(event.product.id));
    } else {
      add(FavoriteAddRequested(event.product));
    }
  }
}
