part of 'order_bloc.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any order operation.
class OrderInitial extends OrderState {
  const OrderInitial();
}

/// An order operation is in progress.
class OrderLoading extends OrderState {
  const OrderLoading([this.order, this.orderId]);

  final AppOrder? order;
  final String? orderId;

  @override
  List<Object?> get props => [order, orderId];
}

/// The client's order list has been successfully loaded.
class ClientOrdersLoaded extends OrderState {
  const ClientOrdersLoaded(this.orders);

  final List<AppOrder> orders;

  @override
  List<Object?> get props => [orders];
}

/// The merchant's order list has been successfully loaded.
class MerchantOrdersLoaded extends OrderState {
  const MerchantOrdersLoaded(this.orders);

  final List<AppOrder> orders;

  @override
  List<Object?> get props => [orders];
}

/// A single order detail has been successfully loaded.
class OrderDetailLoaded extends OrderState {
  const OrderDetailLoaded(this.order);

  final AppOrder order;

  @override
  List<Object?> get props => [order];
}

/// A new order was successfully created.
class OrderCreated extends OrderState {
  const OrderCreated(this.orders);

  final List<AppOrder> orders;

  @override
  List<Object?> get props => [orders];
}

/// An order's status was successfully updated.
class OrderStatusUpdated extends OrderState {
  const OrderStatusUpdated(this.order, {this.orderId});

  final AppOrder order;
  final String? orderId;

  @override
  List<Object?> get props => [order, orderId];
}

/// An order operation failed.
class OrderFailure extends OrderState {
  const OrderFailure(this.message, {this.error, this.order, this.orderId});

  final String message;
  final ApiException? error;
  final AppOrder? order;
  final String? orderId;

  @override
  List<Object?> get props => [message, error, order, orderId];
}
