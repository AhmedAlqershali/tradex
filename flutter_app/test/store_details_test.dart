import 'package:ai_saas/core/services/store_service.dart';
import 'package:ai_saas/shared/models/product_model.dart';
import 'package:ai_saas/shared/models/store_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_saas/presentation/blocs/store/store_bloc.dart';
import 'package:ai_saas/presentation/blocs/product/product_bloc.dart';
import 'package:ai_saas/screens/store_details_screen.dart';
import 'package:ai_saas/screens/search_screen.dart';

class RecordingStoreBloc extends StoreBloc {
  final events = <StoreEvent>[];

  @override
  void add(StoreEvent event) {
    events.add(event);
  }

  void loadStore(StoreModel store) => emit(StoreDetailLoaded(store));

  void loadProducts(String storeId, List<Product> products) =>
      emit(StoreProductsLoaded(products, storeId));
}

class RecordingProductBloc extends ProductBloc {
  final events = <ProductEvent>[];

  @override
  void add(ProductEvent event) {
    events.add(event);
  }

  void fail() => emit(const ProductFailure('Search failed'));
}

void main() {
  Map<String, dynamic> productJson(int id) => {
        'id': id,
        'store_id': 7,
        'name': 'Product $id',
        'store_name': 'Test Store',
        'price': 10,
        'quantity': 2,
        'status': 'active',
        'images': [],
        'created_at': '2026-01-01T00:00:00Z',
      };

  test('parses store ID, phone, and production image URL', () {
    final store = StoreModel.fromServerJson({
      'id': 7,
      'store_name': 'Test Store',
      'description': 'A public store',
      'region': 'Gaza',
      'phone': '0500000000',
      'logo': 'logos/store.jpg',
    });

    expect(store.id, '7');
    expect(store.phone, '0500000000');
    expect(store.imageUrl, contains('/storage/logos/store.jpg'));
    expect(store.imageUrl, isNot(contains('localhost')));
    expect(store.imageUrl, isNot(contains('127.0.0.1')));

    final product = Product.fromServerJson({
      ...productJson(1),
      'images': [
        {'url': 'https://tradex-v2us.onrender.com/storage/products/item.jpg'},
      ],
    });
    expect(product.imageUrl, contains('/storage/products/item.jpg'));
  });

  test('parses every Laravel product page and its pagination metadata', () {
    final firstPage = {
      'success': true,
      'data': {
        'data': [productJson(1), productJson(2)],
        'pagination': {'current_page': 1, 'last_page': 2, 'total': 3},
      },
    };
    final secondPage = {
      'success': true,
      'data': {
        'data': [productJson(3)],
        'pagination': {'current_page': 2, 'last_page': 2, 'total': 3},
      },
    };

    expect(StoreService.parseProductsPageForTesting(firstPage), hasLength(2));
    expect(StoreService.parseProductsPageForTesting(secondPage), hasLength(1));
    expect(
      StoreService.extractPaginationForTesting(firstPage)?['last_page'],
      2,
    );
  });

  testWidgets('Store Details starts loading with the selected store ID',
      (tester) async {
    final bloc = RecordingStoreBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: StoreDetailsScreen(
            store: StoreModel(
              id: '42',
              title: 'Selected Store',
              subTitle: '',
              imageUrl: '',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect((bloc.events.single as StoreByIdRequested).id, '42');
  });

  testWidgets('Store Details loads products and renders the empty state',
      (tester) async {
    final bloc = RecordingStoreBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: StoreDetailsScreen(
            store: StoreModel(
              id: '42',
              title: 'Selected Store',
              subTitle: '',
              imageUrl: '',
            ),
          ),
        ),
      ),
    );

    bloc.loadStore(StoreModel(
      id: '42',
      title: 'Selected Store',
      subTitle: '',
      imageUrl: '',
    ));
    await tester.pump();
    expect(
      (bloc.events.last as StoreProductsLoadRequested).storeId,
      '42',
    );

    bloc.loadProducts('42', const []);
    await tester.pump();
    expect(find.text('لا توجد منتجات في هذا المتجر'), findsOneWidget);
  });

  testWidgets('Store Details missing-ID retry does not crash', (tester) async {
    final bloc = RecordingStoreBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: StoreDetailsScreen(
            store: StoreModel(title: 'Unselected Store', subTitle: '', imageUrl: ''),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search error retry repeats the unified search request',
      (tester) async {
    final bloc = RecordingProductBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: const SearchScreen(initialQuery: 'shoes'),
        ),
      ),
    );

    bloc.fail();
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));

    expect(bloc.events.last, isA<UnifiedSearchRequested>());
    expect((bloc.events.last as UnifiedSearchRequested).query, 'shoes');
  });
}
