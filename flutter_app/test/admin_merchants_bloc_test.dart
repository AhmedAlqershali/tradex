import 'package:ai_saas/presentation/blocs/admin_merchants/admin_merchants_bloc.dart';
import 'package:ai_saas/shared/models/admin_merchant_model.dart';
import 'package:flutter_test/flutter_test.dart';

AdminMerchantPage _page() => const AdminMerchantPage(
      merchants: [
        AdminMerchant(
          id: '12',
          storeName: 'Tradex Store',
          description: 'Store',
          status: 'active',
          productsCount: 4,
          ordersCount: 8,
        ),
      ],
      pagination: AdminMerchantPagination(
        total: 1,
        perPage: 15,
        currentPage: 1,
        lastPage: 1,
      ),
    );

void main() {
  test('loads merchant list through loading and success states', () async {
    final bloc = AdminMerchantsBloc(
      listMerchants: ({
        String? search,
        String? status,
        int page = 1,
        int perPage = 15,
      }) async =>
          _page(),
    );
    addTearDown(bloc.close);

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminMerchantsLoading>(),
        isA<AdminMerchantsLoaded>().having(
          (state) => state.page.merchants.single.storeName,
          'store name',
          'Tradex Store',
        ),
      ]),
    );

    bloc.add(const AdminMerchantsLoadRequested());
    await states;
  });

  test('keeps the merchant page when a list request fails', () async {
    final bloc = AdminMerchantsBloc(
      listMerchants: ({
        String? search,
        String? status,
        int page = 1,
        int perPage = 15,
      }) async =>
          throw Exception('merchant list unavailable'),
    );
    addTearDown(bloc.close);

    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AdminMerchantsLoading>(),
        isA<AdminMerchantsFailure>().having(
          (state) => state.message,
          'message',
          contains('merchant list unavailable'),
        ),
      ]),
    );

    bloc.add(const AdminMerchantsLoadRequested());
    await states;
  });
}
