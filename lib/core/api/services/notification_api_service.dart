library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../api_endpoints.dart';
import '../models/notification_model.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService(ref.read(dioProvider));
});

class NotificationApiService {
  NotificationApiService(this._dio);
  final Dio _dio;

  /// GET /Notifications?pageNumber=&pageSize=
  /// Trả về `NotificationPage` đã được unwrap envelope.
  Future<NotificationPage> list({
    int pageNumber = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) async {
    final params = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (unreadOnly) 'isRead': false,
    };
    final res = await _dio.get(ApiEndpoints.notifications,
        queryParameters: params);
    final data = res.data;
    if (data is List) {
      return NotificationPage.fromList(data);
    }
    if (data is Map<String, dynamic>) {
      // Backend envelope: { success, data: [...] | { items: [...] } }
      final inner = data['data'];
      if (inner is List) {
        return NotificationPage.fromList(inner);
      }
      if (inner is Map<String, dynamic>) {
        return NotificationPage.fromEnvelope(inner);
      }
      return NotificationPage.fromEnvelope(data);
    }
    return NotificationPage.fromList(const []);
  }

  /// GET /Notifications/unread-count
  Future<int> unreadCount() async {
    final res = await _dio.get(ApiEndpoints.notificationsUnreadCount);
    final data = res.data;
    if (data == null) return 0;
    if (data is num) return data.toInt();
    if (data is Map<String, dynamic>) {
      final inner = data['data'] ?? data['count'];
      if (inner is num) return inner.toInt();
      if (inner is Map && inner['count'] is num) {
        return (inner['count'] as num).toInt();
      }
    }
    return 0;
  }

  /// PUT /Notifications/{id}/read
  Future<void> markRead(String id) async {
    await _dio.put(ApiEndpoints.notificationMarkRead(id));
  }

  /// PUT /Notifications/read-all
  Future<void> markAllRead() async {
    await _dio.put(ApiEndpoints.notificationsReadAll);
  }

  /// POST /Notifications/test-push (dev-only).
  Future<void> testPush(Map<String, dynamic> payload) async {
    await _dio.post('/Notifications/test-push', data: payload);
  }
}
