import 'package:flutter_test/flutter_test.dart';
import 'package:ai_saas/presentation/blocs/client_dashboard/client_dashboard_bloc.dart';
import 'package:ai_saas/shared/models/client_dashboard_model.dart';

ClientDashboardModel _dashboard() {
  return const ClientDashboardModel(ordersCount: 4, favoritesCount: 7);
}

void main() {
  test('loads the authenticated client dashboard counters', () async {
    final bloc = ClientDashboardBloc(
      loadDashboard: () async => _dashboard(),
    );
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientDashboardLoading>(),
        isA<ClientDashboardLoaded>().having(
          (state) => state.dashboard.ordersCount,
          'orders count',
          4,
        ),
      ]),
    );

    bloc.add(const ClientDashboardLoadRequested());
    await states;
    await bloc.close();
  });

  test('exposes client dashboard request failures', () async {
    final bloc = ClientDashboardBloc(
      loadDashboard: () async => throw Exception('dashboard unavailable'),
    );
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ClientDashboardLoading>(),
        isA<ClientDashboardFailure>().having(
          (state) => state.message,
          'message',
          contains('dashboard unavailable'),
        ),
      ]),
    );

    bloc.add(const ClientDashboardLoadRequested());
    await states;
    await bloc.close();
  });
}
