part of 'admin_merchants_bloc.dart';

abstract class AdminMerchantsEvent extends Equatable {
  const AdminMerchantsEvent();

  @override
  List<Object?> get props => [];
}

class AdminMerchantsLoadRequested extends AdminMerchantsEvent {
  const AdminMerchantsLoadRequested();
}

class AdminMerchantsSearchChanged extends AdminMerchantsEvent {
  const AdminMerchantsSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

class AdminMerchantsStatusFilterChanged extends AdminMerchantsEvent {
  const AdminMerchantsStatusFilterChanged(this.status);

  final String? status;

  @override
  List<Object?> get props => [status];
}

class AdminMerchantsPageRequested extends AdminMerchantsEvent {
  const AdminMerchantsPageRequested(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

class AdminMerchantDetailsRequested extends AdminMerchantsEvent {
  const AdminMerchantDetailsRequested(this.merchantId);

  final String merchantId;

  @override
  List<Object?> get props => [merchantId];
}

class AdminMerchantStatusUpdateRequested extends AdminMerchantsEvent {
  const AdminMerchantStatusUpdateRequested({
    required this.merchantId,
    required this.status,
  });

  final String merchantId;
  final String status;

  @override
  List<Object?> get props => [merchantId, status];
}