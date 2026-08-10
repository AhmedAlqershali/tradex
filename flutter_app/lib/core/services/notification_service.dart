import 'package:ai_saas/core/api/api_client.dart';
import 'package:ai_saas/core/api/api_constants.dart';
import 'package:ai_saas/shared/models/notification_model.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  Future<NotificationPage> list({int page = 1, int perPage = 20}) async {
    final response = await ApiClient.instance.get<Map<String, dynamic>>(
      ApiConstants.notifications,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final body = _map(response.data);
    final payload = body['data'];
    final pageData = payload is Map ? Map<String, dynamic>.from(payload) : {};
    final rawItems = pageData['data'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) =>
                AppNotification.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <AppNotification>[];
    final pagination = pageData['pagination'] is Map
        ? Map<String, dynamic>.from(pageData['pagination'] as Map)
        : const <String, dynamic>{};

    return NotificationPage(
      items: items,
      currentPage: _int(pagination['current_page'], page),
      lastPage: _int(pagination['last_page'], page),
      unreadCount: items.where((item) => !item.isRead).length,
    );
  }

  Future<AppNotification> markRead(String id) async {
    final response = await ApiClient.instance.patch<Map<String, dynamic>>(
      ApiConstants.notificationById(id),
    );
    final body = _map(response.data);
    final data = body['data'];
    if (data is! Map) {
      throw const FormatException('Notification response was malformed.');
    }
    return AppNotification.fromJson(Map<String, dynamic>.from(data));
  }

  Future<int> markAllRead() async {
    final response = await ApiClient.instance.post<Map<String, dynamic>>(
      ApiConstants.notificationsReadAll,
    );
    final body = _map(response.data);
    final data = body['data'];
    return data is Map ? _int(data['updated_count'], 0) : 0;
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  int _int(Object? value, int fallback) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.unreadCount,
  });

  final List<AppNotification> items;
  final int currentPage;
  final int lastPage;
  final int unreadCount;

  bool get hasNextPage => currentPage < lastPage;
}
