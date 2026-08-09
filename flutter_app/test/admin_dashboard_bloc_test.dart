import 'package:ai_saas/presentation/blocs/admin_dashboard/admin_dashboard_bloc.dart';
import 'package:ai_saas/shared/models/admin_dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';

AdminDashboardModel _dashboard() => AdminDashboardModel.fromJson({
      'system_overview': {
        'users': {'total': 3, 'clients': 1, 'merchants': 2, 'admins': 0},
        'stores': {'total': 2, 'active': 1, 'inactive': 0, 'suspended': 1},
        'products': {
          'total': 4,
          'active': 3,
          'inactive': 0,
          'out_of_stock': 1,
        },
        'orders': {
          'total': 5,
          'pending': 2,
          'confirmed': 1,
          'processing': 1,
          'completed': 1,
          'cancelled': 0,
        },
        'total_sales': 125.5,
      },
      'marketplace': {
        'newest_users': [],
        'newest_stores': [],
        'newest_products': [],
        'recent_orders': [],
      },
    });

void main() {
  test('loads real admin dashboard data through loading and success', () async {
    final bloc = AdminDashboardBloc(loadDashboard: () async => _dashboard());
    addTearDown(bloc.close);

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminDashboardLoading>(),
        isA<AdminDashboardLoaded>().having(
          (state) => state.dashboard.overview.users.merchants,
          'merchant count',
          2,
        ),
      ]),
    );

    bloc.add(const AdminDashboardLoadRequested());
    await states;
  });

  test('exposes admin dashboard failures', () async {
    final bloc = AdminDashboardBloc(
      loadDashboard: () async => throw Exception('dashboard unavailable'),
    );
    addTearDown(bloc.close);

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminDashboardLoading>(),
        isA<AdminDashboardFailure>().having(
          (state) => state.message,
          'message',
          contains('dashboard unavailable'),
        ),
      ]),
    );

    bloc.add(const AdminDashboardLoadRequested());
    await states;
  });
}
