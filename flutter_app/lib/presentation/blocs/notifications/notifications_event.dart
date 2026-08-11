part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationsEvent {
  const NotificationsLoadRequested({this.completer});

  final Completer<void>? completer;
}

class NotificationReadRequested extends NotificationsEvent {
  const NotificationReadRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class NotificationsMarkAllReadRequested extends NotificationsEvent {
  const NotificationsMarkAllReadRequested();
}

class NotificationsNextPageRequested extends NotificationsEvent {
  const NotificationsNextPageRequested();
}
