import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/order_service.dart';
import 'package:ai_saas/shared/models/mock_order.dart';
import 'package:ai_saas/shared/orders/order_controller.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc() : super(const OrderInitial()) {
    on<ClientOrdersLoadRequested>(_onClientOrdersLoadRequested);
    on<MerchantOrdersLoadRequested>(_onMerchantOrdersLoadRequested);
    on<OrderByRefRequested>(_onOrderByRefRequested);
    on<OrderCreateRequested>(_onOrderCreateRequested);
    on<OrderStatusUpdateRequested>(_onOrderStatusUpdateRequested);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _errorMessage(Object e) {
    if (e is ApiException) return e.message;
    return e.toString();
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
      emit(OrderFailure(_errorMessage(e)));
    }
  }

  Future<void> _onMerchantOrdersLoadRequested(
    MerchantOrdersLoadRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final orders = await OrderService.instance.getMerchantOrders();
      // Sync local controller for any ValueListenableBuilder dependencies.
      OrderController.instance.setOrders(orders);
      emit(MerchantOrdersLoaded(orders));
    } catch (e) {
      emit(OrderFailure(_errorMessage(e)));
    }
  }

  Future<void> _onOrderByRefRequested(
    OrderByRefRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      final order = await OrderService.instance.getOrderByRef(event.ref);
      emit(OrderDetailLoaded(order));
    } catch (e) {
      emit(OrderFailure(_errorMessage(e)));
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

      final serverOrder = await OrderService.instance.createOrder(
        customerName: event.customerName,
        customerPhone: event.customerPhone,
        customerCity: event.customerCity,
        notes: event.notes,
        items: items,
      );

      // Prefer the server-assigned ref; if the service returns a minimal
      // response, fill in the local fields for immediate display.
      final order = serverOrder.ref.isNotEmpty
          ? serverOrder
          : AppOrder(
              ref: generateOrderRef(),
              createdAt: DateTime.now(),
              status: OrderStatus.pendingReview,
              products: event.products,
              customerName: event.customerName,
              customerPhone: event.customerPhone,
              customerEmail: event.customerEmail,
              customerCity: event.customerCity,
              customerArea: event.customerArea,
              notes: event.notes,
            );

      // Register in the local controller so ValueListenableBuilder widgets
      // (e.g. ClientOrderDetailsScreen) can watch status updates.
      OrderController.instance.createOrder(order);
      emit(OrderCreated(order));
    } catch (e) {
      emit(OrderFailure(_errorMessage(e)));
    }
  }

  Future<void> _onOrderStatusUpdateRequested(
    OrderStatusUpdateRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading());
    try {
      await OrderService.instance.patchStatus(
        ref: event.ref,
        status: event.status,
      );

      // Update the local controller cache so all ValueListenableBuilder
      // widgets reflect the new status immediately.
      final newStatus = OrderController.parseStatus(event.status);
      OrderController.instance.updateOrderStatus(event.ref, newStatus);

      // Retrieve the updated order from the local controller.
      final orders = OrderController.instance.orders;
      final order = orders.firstWhere(
        (o) => o.ref == event.ref,
        orElse: () => throw const UnknownException('Order not found.'),
      );
      emit(OrderStatusUpdated(order));
    } catch (e) {
      emit(OrderFailure(_errorMessage(e)));
    }
  }
}
