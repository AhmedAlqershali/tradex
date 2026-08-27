part of 'notifications_bloc.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading({this.items = const []});

  final List<AppNotification> items;

  @override
  List<Object?> get props => [items];
}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(
    this.items,
    this.lastPage, {
    this.currentPage = 1,
    this.unreadCount = 0,
  });

  final List<AppNotification> items;
  final int lastPage;
  final int currentPage;
  final int unreadCount;

  bool get hasNextPage => currentPage < lastPage;

  @override
  List<Object?> get props => [items, lastPage, currentPage, unreadCount];
}

class NotificationsFailure extends NotificationsState {
  const NotificationsFailure(this.message, [this.items = const []]);

  final String message;
  final List<AppNotification> items;

  @override
  List<Object?> get props => [message, items];
}
