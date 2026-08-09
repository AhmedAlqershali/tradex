import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/admin_ai_analytics_service.dart';
import 'package:ai_saas/core/services/admin_analytics_service.dart';
import 'package:ai_saas/shared/models/admin_ai_insight_model.dart';
import 'package:ai_saas/shared/models/admin_analytics_model.dart';

part 'admin_analytics_event.dart';
part 'admin_analytics_state.dart';

class AdminAnalyticsBloc
    extends Bloc<AdminAnalyticsEvent, AdminAnalyticsState> {
  AdminAnalyticsBloc({
    Future<AdminAnalyticsModel> Function()? loadAnalytics,
    Future<AdminAiInsight> Function()? generateAiInsight,
  })  : _loadAnalytics =
            loadAnalytics ?? AdminAnalyticsService.instance.getAnalytics,
        _generateAiInsight =
            generateAiInsight ?? AdminAiAnalyticsService.instance.generate,
        super(const AdminAnalyticsInitial()) {
    on<AdminAnalyticsLoadRequested>(_onLoadRequested);
    on<AdminAiInsightsRequested>(_onAiInsightsRequested);
  }

  final Future<AdminAnalyticsModel> Function() _loadAnalytics;
  final Future<AdminAiInsight> Function() _generateAiInsight;
  int _analyticsRequestVersion = 0;
  int _aiRequestVersion = 0;

  Future<void> _onLoadRequested(
    AdminAnalyticsLoadRequested event,
    Emitter<AdminAnalyticsState> emit,
  ) async {
    final requestVersion = ++_analyticsRequestVersion;
    ++_aiRequestVersion;
    emit(const AdminAnalyticsLoading());
    try {
      final analytics = await _loadAnalytics();
      if (!isClosed && requestVersion == _analyticsRequestVersion) {
        emit(AdminAnalyticsLoaded(analytics));
      }
    } on ApiException catch (e) {
      if (!isClosed) emit(AdminAnalyticsFailure(e.message));
    } catch (e) {
      if (!isClosed) emit(AdminAnalyticsFailure(e.toString()));
    }
  }

  Future<void> _onAiInsightsRequested(
    AdminAiInsightsRequested event,
    Emitter<AdminAnalyticsState> emit,
  ) async {
    final current = state;
    if (current is! AdminAnalyticsLoaded || current.aiLoading) return;

    final analyticsVersion = _analyticsRequestVersion;
    final aiRequestVersion = ++_aiRequestVersion;
    emit(AdminAnalyticsLoaded(
      current.analytics,
      aiInsight: current.aiInsight,
      aiLoading: true,
    ));

    try {
      final insight = await _generateAiInsight();
      if (!isClosed &&
          analyticsVersion == _analyticsRequestVersion &&
          aiRequestVersion == _aiRequestVersion) {
        emit(AdminAnalyticsLoaded(
          current.analytics,
          aiInsight: insight,
        ));
      }
    } on ApiException catch (e) {
      if (analyticsVersion == _analyticsRequestVersion &&
          aiRequestVersion == _aiRequestVersion) {
        _emitAiFailure(emit, current, e.message);
      }
    } catch (e) {
      if (analyticsVersion == _analyticsRequestVersion &&
          aiRequestVersion == _aiRequestVersion) {
        _emitAiFailure(emit, current, e.toString());
      }
    }
  }

  void _emitAiFailure(
    Emitter<AdminAnalyticsState> emit,
    AdminAnalyticsLoaded current,
    String message,
  ) {
    if (!isClosed) {
      emit(AdminAnalyticsLoaded(
        current.analytics,
        aiInsight: current.aiInsight,
        aiError: message,
      ));
    }
  }
}
