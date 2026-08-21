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

/// Requests loading a single order by its numeric server id.
class OrderByIdRequested extends OrderEvent {
  const OrderByIdRequested(this.id, {this.asMerchant = true});

  final String id;
  final bool asMerchant;

  @override
  List<Object?> get props => [id, asMerchant];
}

/// Requests creating a new order from checkout data.
class OrderCreateRequested extends OrderEvent {
  const OrderCreateRequested({
    required this.customerName,
    required this.customerPhone,
    required this.customerCity,
    this.notes,
  });

  final String customerName;
  final String customerPhone;
  final String customerCity;
  final String? notes;

  @override
  List<Object?> get props => [
        customerName,
        customerPhone,
        customerCity,
        notes,
      ];
}

/// Requests updating the status of an existing order (merchant action).
class OrderStatusUpdateRequested extends OrderEvent {
  const OrderStatusUpdateRequested({required this.id, required this.status});

  final String id;
  final String status;

  @override
  List<Object?> get props => [id, status];
}
