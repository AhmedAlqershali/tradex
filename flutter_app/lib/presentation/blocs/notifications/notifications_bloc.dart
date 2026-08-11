import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ai_saas/core/api/api_exception.dart';
import 'package:ai_saas/core/services/notification_service.dart';
import 'package:ai_saas/shared/models/notification_model.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    Future<NotificationPage> Function({int page, int perPage})? load,
    Future<AppNotification> Function(String id)? markRead,
    Future<int> Function()? markAllRead,
  })  : _load = load ?? NotificationService.instance.list,
        _markRead = markRead ?? NotificationService.instance.markRead,
        _markAllRead = markAllRead ?? NotificationService.instance.markAllRead,
        super(const NotificationsInitial()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationReadRequested>(_onRead);
    on<NotificationsMarkAllReadRequested>(_onMarkAllRead);
    on<NotificationsNextPageRequested>(_onNextPage);
  }

  final Future<NotificationPage> Function({int page, int perPage}) _load;
  final Future<AppNotification> Function(String id) _markRead;
  final Future<int> Function() _markAllRead;

  int _page = 1;
  List<AppNotification> _items = const [];
  int _lastPage = 1;

  /// Reloads from Laravel and completes only after the request has finished.
  ///
  /// This is used by [RefreshIndicator] so its progress cannot finish before
  /// the authoritative server state has been applied.
  Future<void> refresh() {
    final completer = Completer<void>();
    add(NotificationsLoadRequested(completer: completer));
    return completer.future;
  }

  Future<void> _onLoad(
    NotificationsLoadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    _page = 1;
    try {
      await _fetch(emit, replace: true);
    } finally {
      final completer = event.completer;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<void> _onNextPage(
    NotificationsNextPageRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (_page >= _lastPage || state is NotificationsLoading) return;
    _page++;
    await _fetch(emit, replace: false);
  }

  Future<void> _fetch(
    Emitter<NotificationsState> emit, {
    required bool replace,
  }) async {
    final previous = List<AppNotification>.from(_items);
    emit(NotificationsLoading(items: previous));
    try {
      final page = await _load(page: _page, perPage: 20);
      _lastPage = page.lastPage;
      _items = replace ? page.items : [..._items, ...page.items];
      if (!isClosed) {
        emit(NotificationsLoaded(
          _items,
          _lastPage,
          currentPage: _page,
        ));
      }
    } on ApiException catch (e) {
      _page = replace ? 1 : (_page - 1).clamp(1, _lastPage);
      if (!isClosed) emit(NotificationsFailure(e.message, previous));
    } catch (e) {
      _page = replace ? 1 : (_page - 1).clamp(1, _lastPage);
      if (!isClosed) emit(NotificationsFailure(e.toString(), previous));
    }
  }

  Future<void> _onRead(
    NotificationReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final index = _items.indexWhere((item) => item.id == event.id);
    if (index == -1 || _items[index].isRead) return;
    final previous = List<AppNotification>.from(_items);
    // Do not present a successful local read before Laravel confirms it.
    // Otherwise a failed PATCH briefly looks successful and can be lost on
    // the next server refresh.
    emit(NotificationsLoading(items: previous));
    try {
      final updated = await _markRead(event.id);
      _items = [..._items]..[index] = updated;
      if (!isClosed) {
        emit(NotificationsLoaded(
          _items,
          _lastPage,
          currentPage: _page,
        ));
      }
    } on ApiException catch (e) {
      _items = previous;
      if (!isClosed) emit(NotificationsFailure(e.message, _items));
    } catch (e) {
      _items = previous;
      if (!isClosed) emit(NotificationsFailure(e.toString(), _items));
    }
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (_items.every((item) => item.isRead)) return;
    final previous = List<AppNotification>.from(_items);
    // Wait for the server mutation before changing the visible read state.
    emit(NotificationsLoading(items: previous));
    try {
      await _markAllRead();
      _items = _items.map((item) => item.copyWith(isRead: true)).toList();
      if (!isClosed) {
        emit(NotificationsLoaded(
          _items,
          _lastPage,
          currentPage: _page,
        ));
      }
    } on ApiException catch (e) {
      _items = previous;
      if (!isClosed) emit(NotificationsFailure(e.message, _items));
    } catch (e) {
      _items = previous;
      if (!isClosed) emit(NotificationsFailure(e.toString(), _items));
    }
  }
}
