import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/admin_review_service.dart';
import 'package:ai_saas/shared/models/admin_review_model.dart';

part 'admin_reviews_event.dart';
part 'admin_reviews_state.dart';

class AdminReviewsBloc extends Bloc<AdminReviewsEvent, AdminReviewsState> {
  AdminReviewsBloc() : super(const AdminReviewsInitial()) {
    on<AdminReviewsLoadRequested>(_onLoadRequested);
    on<AdminReviewsPageRequested>(_onPageRequested);
    on<AdminReviewDeleteRequested>(_onDeleteRequested);
  }

  static const _perPage = 15;
  String _productId = '';
  int _page = 1;

  Future<void> _onLoadRequested(
    AdminReviewsLoadRequested event,
    Emitter<AdminReviewsState> emit,
  ) async {
    _productId = event.productId.trim();
    _page = 1;
    await _fetch(emit);
  }

  Future<void> _onPageRequested(
    AdminReviewsPageRequested event,
    Emitter<AdminReviewsState> emit,
  ) async {
    _page = event.page;
    await _fetch(emit);
  }

  Future<void> _onDeleteRequested(
    AdminReviewDeleteRequested event,
    Emitter<AdminReviewsState> emit,
  ) async {
    final previous = _pageFromState(state);
    emit(AdminReviewsLoading(previousPage: previous, productId: _productId));
    try {
      await AdminReviewService.instance.deleteReview(event.reviewId);
      await _fetch(emit);
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  Future<void> _fetch(Emitter<AdminReviewsState> emit) async {
    final previous = _pageFromState(state);
    emit(AdminReviewsLoading(previousPage: previous, productId: _productId));
    try {
      final page = await AdminReviewService.instance.listReviews(
        productId: _productId,
        page: _page,
        perPage: _perPage,
      );
      if (!isClosed) {
        emit(AdminReviewsLoaded(page: page, productId: _productId));
      }
    } on ApiException catch (e) {
      _emitFailure(emit, e.message, previous);
    } catch (e) {
      _emitFailure(emit, e.toString(), previous);
    }
  }

  void _emitFailure(
    Emitter<AdminReviewsState> emit,
    String message,
    AdminReviewPage? previous,
  ) {
    if (!isClosed) {
      emit(AdminReviewsFailure(
        message,
        previousPage: previous,
        productId: _productId,
      ));
    }
  }

  AdminReviewPage? _pageFromState(AdminReviewsState current) {
    if (current is AdminReviewsLoaded) return current.page;
    if (current is AdminReviewsLoading) return current.previousPage;
    if (current is AdminReviewsFailure) return current.previousPage;
    return null;
  }
}
