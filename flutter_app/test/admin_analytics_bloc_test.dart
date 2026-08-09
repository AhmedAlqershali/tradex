import 'dart:async';

import 'package:ai_saas/presentation/blocs/admin_analytics/admin_analytics_bloc.dart';
import 'package:ai_saas/shared/models/admin_ai_insight_model.dart';
import 'package:ai_saas/shared/models/admin_analytics_model.dart';
import 'package:flutter_test/flutter_test.dart';

AdminAnalyticsModel _analytics(int completedOrders) {
  return AdminAnalyticsModel(
    sales: const AdminSalesStatistics(monthlySales: []),
    orders: AdminOrderStatistics(
      byStatus: AdminOrderStatusCounts(
        pending: 0,
        confirmed: 0,
        processing: 0,
        completed: completedOrders,
        cancelled: 0,
      ),
    ),
    userGrowth: const [],
    merchantGrowth: const [],
    products: const AdminProductStatistics(
      byCategory: [],
      byStatus: AdminProductStatusCounts(
        active: 0,
        inactive: 0,
        outOfStock: 0,
      ),
    ),
  );
}

AdminAiInsight _insight(String result) {
  return AdminAiInsight(
    result: result,
    periodDays: 30,
    type: 'overview',
    language: 'Arabic',
    tokensUsed: 1,
  );
}

void main() {
  test('AI insights emit loading and success through the BLoC', () async {
    final bloc = AdminAnalyticsBloc(
      loadAnalytics: () async => _analytics(1),
      generateAiInsight: () async => _insight('تحليل جاهز'),
    );
    addTearDown(bloc.close);

    bloc.add(const AdminAnalyticsLoadRequested());
    await expectLater(
      bloc.stream,
      emitsThrough(isA<AdminAnalyticsLoaded>()),
    );

    bloc.add(const AdminAiInsightsRequested());
    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminAnalyticsLoaded>().having(
          (state) => state.aiLoading,
          'aiLoading',
          true,
        ),
        isA<AdminAnalyticsLoaded>()
            .having((state) => state.aiInsight?.result, 'result', 'تحليل جاهز'),
      ]),
    );
  });

  test('AI failures are exposed as an error state without losing analytics',
      () async {
    final bloc = AdminAnalyticsBloc(
      loadAnalytics: () async => _analytics(2),
      generateAiInsight: () async => throw StateError('provider unavailable'),
    );
    addTearDown(bloc.close);

    bloc.add(const AdminAnalyticsLoadRequested());
    await expectLater(bloc.stream, emitsThrough(isA<AdminAnalyticsLoaded>()));

    bloc.add(const AdminAiInsightsRequested());
    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminAnalyticsLoaded>().having(
          (state) => state.aiLoading,
          'aiLoading',
          true,
        ),
        isA<AdminAnalyticsLoaded>()
            .having((state) => state.aiError, 'aiError',
                contains('provider unavailable'))
            .having((state) => state.analytics.orders.byStatus.completed,
                'completed orders', 2),
      ]),
    );
  });

  test('a refresh invalidates an in-flight AI result', () async {
    final aiCompleter = Completer<AdminAiInsight>();
    var loadCount = 0;
    final bloc = AdminAnalyticsBloc(
      loadAnalytics: () async => _analytics(++loadCount),
      generateAiInsight: () => aiCompleter.future,
    );
    addTearDown(bloc.close);

    bloc.add(const AdminAnalyticsLoadRequested());
    await expectLater(bloc.stream, emitsThrough(isA<AdminAnalyticsLoaded>()));

    bloc.add(const AdminAiInsightsRequested());
    await expectLater(
      bloc.stream,
      emitsThrough(
        isA<AdminAnalyticsLoaded>().having(
          (state) => state.aiLoading,
          'aiLoading',
          true,
        ),
      ),
    );

    bloc.add(const AdminAnalyticsLoadRequested());
    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminAnalyticsLoading>(),
        isA<AdminAnalyticsLoaded>().having(
          (state) => state.analytics.orders.byStatus.completed,
          'refreshed completed orders',
          2,
        ),
      ]),
    );

    aiCompleter.complete(_insight('stale result'));
    await Future<void>.delayed(Duration.zero);
    expect(
      bloc.state,
      isA<AdminAnalyticsLoaded>()
          .having((state) => state.analytics.orders.byStatus.completed,
              'current completed orders', 2)
          .having((state) => state.aiInsight, 'AI insight', isNull),
    );
  });
}
