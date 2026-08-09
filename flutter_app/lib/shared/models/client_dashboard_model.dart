import 'package:equatable/equatable.dart';

/// Lightweight counters returned for the authenticated client dashboard.
class ClientDashboardModel extends Equatable {
  const ClientDashboardModel({
    required this.ordersCount,
    required this.favoritesCount,
  });

  final int ordersCount;
  final int favoritesCount;

  factory ClientDashboardModel.fromJson(Map<String, dynamic> json) {
    return ClientDashboardModel(
      ordersCount: _integer(json['orders_count']),
      favoritesCount: _integer(json['favorites_count']),
    );
  }

  @override
  List<Object?> get props => [ordersCount, favoritesCount];
}

int _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
