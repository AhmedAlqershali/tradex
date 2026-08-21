import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/order_service.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  AppOrder? _currentOrder;
  final Set<String> _statusUpdatesInFlight = <String>{};
  final Map<String, int> _orderRequestVersions = <String, int>{};
  final Map<String, AppOrder> _latestUpdatedOrders = <String, AppOrder>{};
  OrderBloc() : super(const OrderInitial()) {
    on<ClientOrdersLoadRequested>(_onClientOrdersLoadRequested);
    on<MerchantOrdersLoadRequested>(_onMerchantOrdersLoadRequested);
    on<OrderByIdRequested>(_onOrderByIdRequested);
    on<OrderCreateRequested>(_onOrderCreateRequested);
    on<OrderStatusUpdateRequested>(_onOrderStatusUpdateRequested);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _errorMessage(Object e) {
    if (e is ApiException) return e.message;
    return e.toString();
  }

  OrderFailure _failure(Object e, {AppOrder? order, String? orderId}) {
    return e is ApiException
        ? OrderFailure(e.message, error: e, order: order, orderId: orderId)
        : OrderFailure(_errorMessage(e), order: order, orderId: orderId);
  }

  // ── Handlers ─────────────────────────────────────────────────────────────────

  Future<void> _onClientOrdersLoadRequested(
    ClientOrdersLoadRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final orders = await OrderService.instance.getClientOrders();
      // Sync local controller so ValueListenableBuilder widgets (e.g.
      // ClientOrderDetailsScreen) reflect the latest server data.
      OrderController.instance.setOrders(orders);
      emit(ClientOrdersLoaded(orders));
    } catch (e) {
      emit(_failure(e));
    }
  }

  Future<void> _onMerchantOrdersLoadRequested(
    MerchantOrdersLoadRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final orders = await OrderService.instance.getMerchantOrders(
        status: event.status,
      );
      // Sync local controller for any ValueListenableBuilder dependencies.
      OrderController.instance.setOrders(orders);
      emit(MerchantOrdersLoaded(orders));
    } catch (e) {
      emit(_failure(e));
    }
  }

  Future<void> _onOrderByIdRequested(
    OrderByIdRequested event,
    Emitter<OrderState> emit,
  ) async {
    final requestVersion =
        (_orderRequestVersions[event.id] ?? 0) + 1;
    _orderRequestVersions[event.id] = requestVersion;
    final previousOrder =
        _currentOrder?.serverId == event.id ? _currentOrder : null;
    emit(OrderLoading(previousOrder, event.id));
    try {
      var order = await OrderService.instance.getOrderById(
        event.id,
        asMerchant: event.asMerchant,
      );
      if (_orderRequestVersions[event.id] != requestVersion) {
        debugPrint('[OrderBloc] stale detail response ignored: '
            'serverId=${event.id} version=$requestVersion');
        return;
      }

      final latestUpdated = _latestUpdatedOrders[event.id];
      if (latestUpdated != null && order.status != latestUpdated.status) {
        debugPrint('[OrderBloc] stale detail status replaced: '
            'serverId=${event.id} response=${order.status.name} '
            'latest=${latestUpdated.status.name}');
        order = latestUpdated;
      } else if (latestUpdated != null) {
        _latestUpdatedOrders.remove(event.id);
      }
      _currentOrder = order;
      emit(OrderDetailLoaded(order));
    } catch (e) {
      if (_orderRequestVersions[event.id] != requestVersion) {
        debugPrint('[OrderBloc] stale detail failure ignored: '
            'serverId=${event.id} version=$requestVersion');
        return;
      }
      emit(_failure(e, order: previousOrder));
    }
  }

  Future<void> _onOrderCreateRequested(
    OrderCreateRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final serverOrders = await OrderService.instance.createOrder(
        customerName: event.customerName,
        customerPhone: event.customerPhone,
        customerCity: event.customerCity,
        notes: event.notes,
      );

      // A successful checkout must always contain server-created orders. Never
      // fabricate a local order when the API returns an empty/malformed body.
      if (serverOrders.isEmpty) {
        throw StateError('Checkout succeeded without a server order.');
      }
      final orders = serverOrders;
      OrderController.instance.setOrders([
        ...orders,
        ...OrderController.instance.orders.where(
          (existing) => !orders.any((order) => order.ref == existing.ref),
        ),
      ]);
      emit(OrderCreated(orders));
    } catch (e) {
      emit(_failure(e));
    }
  }

  Future<void> _onOrderStatusUpdateRequested(
    OrderStatusUpdateRequested event,
    Emitter<OrderState> emit,
  ) async {
    if (!_statusUpdatesInFlight.add(event.id)) {
      debugPrint('[OrderBloc] status update ignored: already in flight '
          'serverId=${event.id}');
      return;
    }

    final currentOrder =
        _currentOrder?.serverId == event.id ? _currentOrder : null;
    debugPrint('[OrderBloc] status update started: serverId=${event.id}, '
        'currentStatus=${currentOrder?.status.name}, target=${event.status}');
    emit(OrderLoading(currentOrder, event.id));
    try {
      final updatedOrder = await OrderService.instance.patchStatus(
        id: event.id,
        status: event.status,
      );
      _latestUpdatedOrders[event.id] = updatedOrder;
      _currentOrder = updatedOrder;

      // Update the local controller cache so all ValueListenableBuilder
      // widgets reflect the new status immediately.
      OrderController.instance.setOrders([
        ...OrderController.instance.orders
            .where((order) => order.serverId != updatedOrder.serverId),
        updatedOrder,
      ]);
      debugPrint('[OrderBloc] status update succeeded: serverId=${event.id}, '
          'status=${updatedOrder.status.name}');
      emit(OrderStatusUpdated(updatedOrder, orderId: event.id));
    } catch (e) {
      debugPrint('[OrderBloc] status update failed: serverId=${event.id}, '
          'error=${_errorMessage(e)}');
      emit(_failure(e, order: currentOrder, orderId: event.id));
    } finally {
      _statusUpdatesInFlight.remove(event.id);
    }
  }
}
