import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/order_service.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';

part 'order_event.dart';
part 'order_state.dart';

typedef OrderStatusPatcher = Future<AppOrder> Function({
  required String id,
  required String status,
});

typedef OrderDetailLoader = Future<AppOrder> Function(
  String id, {
  bool asMerchant,
});

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  AppOrder? _currentOrder;
  final Set<String> _statusUpdatesInFlight = <String>{};
  final Map<String, int> _orderRequestVersions = <String, int>{};
  final Map<String, AppOrder> _latestUpdatedOrders = <String, AppOrder>{};
  final OrderStatusPatcher _patchStatus;
  final OrderDetailLoader _loadOrder;

  OrderBloc({
    OrderStatusPatcher? patchStatus,
    OrderDetailLoader? loadOrder,
  })  : _patchStatus = patchStatus ?? OrderService.instance.patchStatus,
        _loadOrder = loadOrder ?? OrderService.instance.getOrderById,
        super(const OrderInitial()) {
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
    final requestVersion = (_orderRequestVersions[event.id] ?? 0) + 1;
    _orderRequestVersions[event.id] = requestVersion;
    final previousOrder =
        _currentOrder?.serverId == event.id ? _currentOrder : null;
    emit(OrderLoading(previousOrder, event.id));
    try {
      var order = await _loadOrder(
        event.id,
        asMerchant: event.asMerchant,
      );
      if (_orderRequestVersions[event.id] != requestVersion) {
        return;
      }

      final latestUpdated = _latestUpdatedOrders[event.id];
      if (latestUpdated != null && order.status != latestUpdated.status) {
        order = latestUpdated;
      } else if (latestUpdated != null) {
        _latestUpdatedOrders.remove(event.id);
      }
      _currentOrder = order;
      emit(OrderDetailLoaded(order));
    } catch (e) {
      if (_orderRequestVersions[event.id] != requestVersion) {
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
      return;
    }

    final currentOrder =
        _currentOrder?.serverId == event.id ? _currentOrder : null;
    emit(OrderLoading(currentOrder, event.id));
    try {
      final updatedOrder = await _patchStatus(
        id: event.id,
        status: event.status,
      );
      if (updatedOrder.serverId != event.id) {
        throw StateError(
          'Status update response ID ${updatedOrder.serverId} '
          'does not match requested order ${event.id}.',
        );
      }
      _latestUpdatedOrders[event.id] = updatedOrder;
      _currentOrder = updatedOrder;

      // Update the local controller cache so all ValueListenableBuilder
      // widgets reflect the new status immediately.
      OrderController.instance.setOrders([
        ...OrderController.instance.orders
            .where((order) => order.serverId != updatedOrder.serverId),
        updatedOrder,
      ]);
      emit(OrderStatusUpdated(updatedOrder, orderId: event.id));
    } catch (e) {
      emit(_failure(e, order: currentOrder, orderId: event.id));
    } finally {
      _statusUpdatesInFlight.remove(event.id);
    }
  }
}
