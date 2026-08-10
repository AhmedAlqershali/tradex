import 'package:ai_saas/core/services/notification_service.dart';
import 'package:ai_saas/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:ai_saas/shared/models/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _notification(String id, {bool isRead = false}) {
  return AppNotification(
    id: id,
    type: 'order_status_updated',
    title: 'تحديث الطلب',
    message: 'تم تحديث حالة طلبك.',
    data: const {'order_id': 9},
    isRead: isRead,
  );
}

void main() {
  test('loads notifications and exposes unread count', () async {
    final bloc = NotificationsBloc(
      load: ({page = 1, perPage = 20}) async => NotificationPage(
        items: [_notification('1'), _notification('2', isRead: true)],
        currentPage: page,
        lastPage: 1,
        unreadCount: 1,
      ),
    );

    final states = expectLater(
      bloc.stream,
      emitsThrough(
        isA<NotificationsLoaded>()
            .having((state) => state.items.length, 'item count', 2)
            .having((state) => state.unreadCount, 'unread count', 1),
      ),
    );

    bloc.add(const NotificationsLoadRequested());
    await states;
    await bloc.close();
  });

  test('marks one notification read and rolls back when server fails',
      () async {
    var markReadCalls = 0;
    final bloc = NotificationsBloc(
      load: ({page = 1, perPage = 20}) async => NotificationPage(
        items: [_notification('1')],
        currentPage: page,
        lastPage: 1,
        unreadCount: 1,
      ),
      markRead: (id) async {
        markReadCalls++;
        throw Exception('server unavailable');
      },
    );

    bloc.add(const NotificationsLoadRequested());
    await bloc.stream.firstWhere((state) => state is NotificationsLoaded);
    bloc.add(const NotificationReadRequested('1'));

    final failure = await bloc.stream.firstWhere(
      (state) => state is NotificationsFailure,
    );
    expect(markReadCalls, 1);
    expect((failure as NotificationsFailure).items.single.isRead, isFalse);
    await bloc.close();
  });

  test('marks all notifications read', () async {
    var calls = 0;
    final bloc = NotificationsBloc(
      load: ({page = 1, perPage = 20}) async => NotificationPage(
        items: [_notification('1'), _notification('2')],
        currentPage: page,
        lastPage: 1,
        unreadCount: 2,
      ),
      markAllRead: () async {
        calls++;
        return 2;
      },
    );

    bloc.add(const NotificationsLoadRequested());
    await bloc.stream.firstWhere((state) => state is NotificationsLoaded);
    bloc.add(const NotificationsMarkAllReadRequested());

    final loaded = await bloc.stream.firstWhere(
      (state) => state is NotificationsLoaded && state.unreadCount == 0,
    );
    expect(calls, 1);
    expect((loaded as NotificationsLoaded).items.every((item) => item.isRead),
        isTrue);
    await bloc.close();
  });
}
