import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_saas/presentation/blocs/order/order_bloc.dart';
import 'package:ai_saas/shared/models/mock_order.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';

AppOrder _order({
  required String id,
  required OrderStatus status,
}) {
  return AppOrder(
    ref: id,
    serverId: id,
    createdAt: DateTime.utc(2026, 8, 14, 10),
    status: status,
    products: const [],
    customerName: 'Customer',
    customerPhone: '000',
    customerCity: 'City',
  );
}

void main() {
  tearDown(() {
    OrderController.instance.setOrders([]);
  });

  test('successful status update uses the canonical server order', () async {
    final updated = _order(
      id: '42',
      status: OrderStatus.merchantContacted,
    );
    String? requestedId;
    String? requestedStatus;

    final bloc = OrderBloc(
      patchStatus: ({required id, required status}) async {
        requestedId = id;
        requestedStatus = status;
        return updated;
      },
    );

    final stateFuture = bloc.stream
        .where((state) => state is OrderStatusUpdated)
        .cast<OrderStatusUpdated>()
        .first;
    bloc.add(const OrderStatusUpdateRequested(
      id: '42',
      status: 'merchantContacted',
    ));

    final state = await stateFuture;

    expect(requestedId, '42');
    expect(requestedStatus, 'merchantContacted');
    expect(state.order, same(updated));
    expect(state.orderId, '42');
    expect(state.order.status, OrderStatus.merchantContacted);
    expect(OrderController.instance.orders, [same(updated)]);

    await bloc.close();
  });

  test('stale detail responses cannot replace a newer response', () async {
    final firstResponse = Completer<AppOrder>();
    final secondResponse = Completer<AppOrder>();
    var loadCount = 0;

    final bloc = OrderBloc(
      loadOrder: (id, {asMerchant = true}) {
        loadCount += 1;
        return loadCount == 1 ? firstResponse.future : secondResponse.future;
      },
    );
    final detailStates = <OrderDetailLoaded>[];
    final subscription = bloc.stream
        .where((state) => state is OrderDetailLoaded)
        .cast<OrderDetailLoaded>()
        .listen(detailStates.add);

    bloc.add(const OrderByIdRequested('42'));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const OrderByIdRequested('42'));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(loadCount, 2);
    secondResponse.complete(_order(
      id: '42',
      status: OrderStatus.merchantContacted,
    ));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    firstResponse.complete(_order(
      id: '42',
      status: OrderStatus.pendingReview,
    ));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(detailStates, hasLength(1));
    expect(detailStates.single.order.status, OrderStatus.merchantContacted);

    await subscription.cancel();
    await bloc.close();
  });

  test('reloading after update keeps the persisted server status', () async {
    final updated = _order(
      id: '42',
      status: OrderStatus.merchantContacted,
    );

    final bloc = OrderBloc(
      patchStatus: ({required id, required status}) async => updated,
      loadOrder: (id, {asMerchant = true}) async => updated,
    );

    final updatedFuture = bloc.stream
        .where((state) => state is OrderStatusUpdated)
        .cast<OrderStatusUpdated>()
        .first;
    bloc.add(const OrderStatusUpdateRequested(
      id: '42',
      status: 'merchantContacted',
    ));
    await updatedFuture;

    final reloadFuture = bloc.stream
        .where((state) => state is OrderDetailLoaded)
        .cast<OrderDetailLoaded>()
        .first;
    bloc.add(const OrderByIdRequested('42'));
    final reloaded = await reloadFuture;

    expect(reloaded.order.serverId, '42');
    expect(reloaded.order.status, OrderStatus.merchantContacted);

    await bloc.close();
  });
}
