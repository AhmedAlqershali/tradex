part of 'order_bloc.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

/// Requests loading all orders for the authenticated client.
class ClientOrdersLoadRequested extends OrderEvent {
  const ClientOrdersLoadRequested();
}

/// Requests loading all orders visible to the authenticated merchant.
class MerchantOrdersLoadRequested extends OrderEvent {
  const MerchantOrdersLoadRequested({this.status});

  /// Backend status filter. Null loads all merchant orders.
  final String? status;

  @override
  List<Object?> get props => [status];
}

/// Requests loading a single order by its reference code.
class OrderByRefRequested extends OrderEvent {
  const OrderByRefRequested(this.ref);

  final String ref;

  @override
  List<Object?> get props => [ref];
}

/// Requests creating a new order from checkout data.
class OrderCreateRequested extends OrderEvent {
  const OrderCreateRequested({
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.customerCity,
    required this.customerArea,
    this.notes,
    required this.products,
  });

  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String customerCity;
  final String customerArea;
  final String? notes;
  final List<AppOrderProduct> products;

  @override
  List<Object?> get props => [
        customerName,
        customerPhone,
        customerEmail,
        customerCity,
        customerArea,
        notes,
        products,
      ];
}

/// Requests updating the status of an existing order (merchant action).
class OrderStatusUpdateRequested extends OrderEvent {
  const OrderStatusUpdateRequested({required this.ref, required this.status});

  final String ref;
  final String status;

  @override
  List<Object?> get props => [ref, status];
}
