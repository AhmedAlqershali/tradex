import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/order_service.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
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

  OrderFailure _failure(Object e) {
    return e is ApiException
        ? OrderFailure(e.message, error: e)
        : OrderFailure(_errorMessage(e));
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
    emit(const OrderLoading());
    try {
      final order = await OrderService.instance.getOrderById(event.id);
      emit(OrderDetailLoaded(order));
    } catch (e) {
      emit(_failure(e));
    }
  }

  Future<void> _onOrderCreateRequested(
    OrderCreateRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      // Build the items snapshot expected by the service.
      final items = event.products
          .map((p) => <String, dynamic>{
                'product_id': p.id,
                'product_name': p.name,
                'price': p.price,
                'quantity': p.quantity,
              })
          .toList();

      final serverOrders = await OrderService.instance.createOrder(
        customerName: event.customerName,
        customerPhone: event.customerPhone,
        customerCity: event.customerCity,
        notes: event.notes,
        items: items,
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
    emit(const OrderLoading());
    try {
      final updatedOrder = await OrderService.instance.patchStatus(
        ref: event.ref,
        status: event.status,
      );

      // Update the local controller cache so all ValueListenableBuilder
      // widgets reflect the new status immediately.
      OrderController.instance.setOrders([
        ...OrderController.instance.orders
            .where((order) => order.ref != updatedOrder.ref),
        updatedOrder,
      ]);
      emit(OrderStatusUpdated(updatedOrder));
    } catch (e) {
      emit(_failure(e));
    }
  }
}
