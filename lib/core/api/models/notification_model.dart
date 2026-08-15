import '../../utils/date_utils.dart';

/// Notification model matching SmartFarm backend API.
///
/// API endpoints:
/// - GET  /api/Notifications?pageNumber=1&pageSize=20
/// - GET  /api/Notifications/unread-count
/// - PUT  /api/Notifications/{id}/read
/// - PUT  /api/Notifications/read-all
/// - POST /api/Notifications/test-push
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.isRead,
    required this.createdAt,
    this.referenceTable,
    this.referenceId,
    this.actionUrl,
    this.metadata,
    this.readAt,
    this.iconName,
    this.color,
  });

  final String id;
  final String title;
  final String message;
  final String type; // Task, Experiment, Alert, System, Measurement
  final String priority; // Critical, High, Medium, Low
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? referenceTable;
  final String? referenceId;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;
  final String? iconName;
  final String? color;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'System',
      priority: json['priority'] as String? ?? 'Medium',
      isRead: json['isRead'] as bool? ?? (json['readAt'] != null),
      createdAt: parseApiDateTimeOrNow(json['createdAt']?.toString()),
      readAt: parseApiDateTime(json['readAt']?.toString()),
      referenceTable: json['referenceTable'] as String?,
      referenceId: json['referenceId']?.toString(),
      actionUrl: json['actionUrl'] as String?,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      iconName: json['iconName'] as String?,
      color: json['color'] as String?,
    );
  }

  bool get isCritical => priority.toLowerCase() == 'critical';
  bool get isHigh => priority.toLowerCase() == 'high';
  bool get isUnread => !isRead;
}

class UnreadCount {
  const UnreadCount({required this.count});
  final int count;

  factory UnreadCount.fromJson(dynamic raw) {
    if (raw == null) return const UnreadCount(count: 0);
    if (raw is num) return UnreadCount(count: raw.toInt());
    if (raw is Map) {
      final c = raw['count'];
      return UnreadCount(count: c is num ? c.toInt() : 0);
    }
    return const UnreadCount(count: 0);
  }
}

/// Notification page response — supports both flat list and paged envelope.
class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    this.hasNextPage = false,
  });

  final List<NotificationModel> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final bool hasNextPage;

  factory NotificationPage.fromList(List<dynamic> data) {
    return NotificationPage(
      items: data
          .whereType<Map>()
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      pageNumber: 1,
      pageSize: data.length,
      totalCount: data.length,
      hasNextPage: false,
    );
  }

  factory NotificationPage.fromEnvelope(Map<String, dynamic> data) {
    final itemsRaw = data['items'] ?? data['data'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map>()
            .map((e) =>
                NotificationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <NotificationModel>[];
    return NotificationPage(
      items: items,
      pageNumber: (data['pageNumber'] as num?)?.toInt() ?? 1,
      pageSize: (data['pageSize'] as num?)?.toInt() ?? items.length,
      totalCount: (data['totalCount'] as num?)?.toInt() ?? items.length,
      hasNextPage: data['hasNextPage'] as bool? ?? false,
    );
  }
}
