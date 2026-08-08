import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/admin_analytics_service.dart';
import 'package:ai_saas/shared/models/admin_analytics_model.dart';

part 'admin_analytics_event.dart';
part 'admin_analytics_state.dart';

class AdminAnalyticsBloc
    extends Bloc<AdminAnalyticsEvent, AdminAnalyticsState> {
  AdminAnalyticsBloc() : super(const AdminAnalyticsInitial()) {
    on<AdminAnalyticsLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    AdminAnalyticsLoadRequested event,
    Emitter<AdminAnalyticsState> emit,
  ) async {
    emit(const AdminAnalyticsLoading());
    try {
      final analytics = await AdminAnalyticsService.instance.getAnalytics();
      if (!isClosed) emit(AdminAnalyticsLoaded(analytics));
    } on ApiException catch (e) {
      if (!isClosed) emit(AdminAnalyticsFailure(e.message));
    } catch (e) {
      if (!isClosed) emit(AdminAnalyticsFailure(e.toString()));
    }
  }
}
