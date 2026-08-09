import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/presentation/blocs/merchant_dashboard/merchant_dashboard_bloc.dart';
import 'package:ai_saas/shared/models/merchant_dashboard_model.dart';

MerchantDashboardModel _dashboard() {
  return MerchantDashboardModel.fromJson({
    'products': {'total': 2, 'active': 2},
    'orders': {'total': 1, 'pending': 1},
    'total_sales': 50,
  });
}

void main() {
  test('loads the authenticated merchant dashboard', () async {
    final bloc = MerchantDashboardBloc(
      loadDashboard: () async => _dashboard(),
    );
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<MerchantDashboardLoading>(),
        isA<MerchantDashboardLoaded>().having(
          (state) => state.dashboard.orders.pending,
          'pending orders',
          1,
        ),
      ]),
    );

    bloc.add(const MerchantDashboardLoadRequested());
    await states;
    await bloc.close();
  });

  test('exposes dashboard request failures', () async {
    final bloc = MerchantDashboardBloc(
      loadDashboard: () async => throw Exception('dashboard unavailable'),
    );
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<MerchantDashboardLoading>(),
        isA<MerchantDashboardFailure>().having(
          (state) => state.message,
          'message',
          contains('dashboard unavailable'),
        ),
      ]),
    );

    bloc.add(const MerchantDashboardLoadRequested());
    await states;
    await bloc.close();
  });
}