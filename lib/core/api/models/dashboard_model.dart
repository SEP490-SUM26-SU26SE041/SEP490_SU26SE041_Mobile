import '../../utils/date_utils.dart';

/// Dashboard overview payload — used by Student / Technician dashboards.
/// Maps to GET /dashboard/overview (with optional farmId / experimentId filters).
class DashboardOverviewModel {
  const DashboardOverviewModel({
    required this.activeExperiments,
    required this.activeBatches,
    required this.pendingTasks,
    required this.completedTasksToday,
    required this.overdueTasks,
    required this.unreadNotifications,
    required this.totalMeasurementRecords,
    required this.criticalAlerts,
    this.recentGrowthRatePercent,
    this.recommendedActions = const [],
    this.topExperiments = const [],
    this.generatedAt,
    this.recentImages = const [],
  });

  final int activeExperiments;
  final int activeBatches;
  final int pendingTasks;
  final int completedTasksToday;
  final int overdueTasks;
  final int unreadNotifications;
  final int totalMeasurementRecords;
  final int criticalAlerts;
  final double? recentGrowthRatePercent;
  final List<DashboardRecommendation> recommendedActions;
  final List<DashboardExperimentSummary> topExperiments;
  final DateTime? generatedAt;

  /// Ảnh cây gần đây từ task-reports — hiển thị trên dashboard.
  final List<TaskImageItem> recentImages;

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    // Support both envelope {data: {...}} and direct object.
    final data = (json['data'] is Map ? json['data'] : json) as Map?;
    if (data == null) return DashboardOverviewModel.empty();
    return DashboardOverviewModel(
      activeExperiments: (data['activeExperiments'] as num?)?.toInt() ?? 0,
      activeBatches: (data['activeBatches'] as num?)?.toInt() ?? 0,
      pendingTasks: (data['pendingTasks'] as num?)?.toInt() ?? 0,
      completedTasksToday: (data['completedTasksToday'] as num?)?.toInt() ?? 0,
      overdueTasks: (data['overdueTasks'] as num?)?.toInt() ?? 0,
      unreadNotifications: (data['unreadNotifications'] as num?)?.toInt() ?? 0,
      totalMeasurementRecords:
          (data['totalMeasurementRecords'] as num?)?.toInt() ?? 0,
      criticalAlerts: (data['criticalAlerts'] as num?)?.toInt() ?? 0,
      recentGrowthRatePercent:
          (data['recentGrowthRatePercent'] as num?)?.toDouble(),
      recommendedActions: (data['recommendedActions'] as List?)
              ?.whereType<Map>()
              .map((e) => DashboardRecommendation.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      topExperiments: (data['topExperiments'] as List?)
              ?.whereType<Map>()
              .map((e) => DashboardExperimentSummary.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      generatedAt: parseApiDateTime(data['generatedAt']?.toString()),
      recentImages: (data['recentImages'] as List?)
              ?.whereType<Map>()
              .map((e) => TaskImageItem.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }

  static DashboardOverviewModel empty() => const DashboardOverviewModel(
        activeExperiments: 0,
        activeBatches: 0,
        pendingTasks: 0,
        completedTasksToday: 0,
        overdueTasks: 0,
        unreadNotifications: 0,
        totalMeasurementRecords: 0,
        criticalAlerts: 0,
      );
}

/// Ảnh task gần đây — hiển thị trên dashboard.
class TaskImageItem {
  const TaskImageItem({
    required this.id,
    required this.imageUrl,
    required this.uploadedAt,
    this.caption,
    this.batchId,
    this.batchCode,
    this.taskId,
    this.taskTitle,
  });

  final String id;
  final String imageUrl;
  final DateTime uploadedAt;
  final String? caption;
  final String? batchId;
  final String? batchCode;
  final String? taskId;
  final String? taskTitle;

  factory TaskImageItem.fromJson(Map<String, dynamic> json) {
    return TaskImageItem(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['url'] as String? ?? '',
      uploadedAt: parseApiDateTimeOrNow(json['uploadedAt']?.toString() ?? json['capturedAt']?.toString()),
      caption: json['caption'] as String?,
      batchId: json['batchId'] as String?,
      batchCode: json['batchCode'] as String?,
      taskId: json['taskId'] as String?,
      taskTitle: json['taskTitle'] as String?,
    );
  }
}

class DashboardRecommendation {
  const DashboardRecommendation({
    required this.title,
    required this.reason,
    required this.severity,
    this.actionLabel,
    this.referenceTable,
    this.referenceId,
  });

  final String title;
  final String reason;
  final String severity; // info, warning, success
  final String? actionLabel;
  final String? referenceTable;
  final String? referenceId;

  factory DashboardRecommendation.fromJson(Map<String, dynamic> json) {
    return DashboardRecommendation(
      title: json['title'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      actionLabel: json['actionLabel'] as String?,
      referenceTable: json['referenceTable'] as String?,
      referenceId: json['referenceId']?.toString(),
    );
  }
}

class DashboardExperimentSummary {
  const DashboardExperimentSummary({
    required this.experimentId,
    required this.experimentCode,
    required this.title,
    required this.progressPercent,
    required this.batchCount,
    required this.status,
  });

  final String experimentId;
  final String experimentCode;
  final String title;
  final double progressPercent;
  final int batchCount;
  final String status;

  factory DashboardExperimentSummary.fromJson(Map<String, dynamic> json) {
    return DashboardExperimentSummary(
      experimentId: json['experimentId']?.toString() ?? '',
      experimentCode: json['experimentCode'] as String? ?? '',
      title: json['title'] as String? ?? '',
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0,
      batchCount: (json['batchCount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'Active',
    );
  }
}

/// Dashboard KPI tile (lighter version of overview).
class DashboardKpiModel {
  const DashboardKpiModel({
    required this.label,
    required this.value,
    required this.iconName,
    required this.color,
    this.subtitle,
    this.trendPercent,
  });

  final String label;
  final num value;
  final String iconName;
  final String color;
  final String? subtitle;
  final double? trendPercent;

  factory DashboardKpiModel.fromJson(Map<String, dynamic> json) {
    return DashboardKpiModel(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?) ?? 0,
      iconName: json['iconName'] as String? ?? 'analytics',
      color: json['color'] as String? ?? 'primary',
      subtitle: json['subtitle'] as String?,
      trendPercent: (json['trendPercent'] as num?)?.toDouble(),
    );
  }
}

/// Alert from /dashboard/alerts or aggregated from notifications.
class DashboardAlertModel {
  const DashboardAlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.referenceTable,
    this.referenceId,
    this.metricName,
    this.currentValue,
    this.thresholdValue,
  });

  final String id;
  final String title;
  final String message;
  final String severity; // critical, high, medium, low
  final DateTime createdAt;
  final String? referenceTable;
  final String? referenceId;
  final String? metricName;
  final double? currentValue;
  final double? thresholdValue;

  factory DashboardAlertModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map ? json['data'] : json) as Map?;
    final src = data ?? json;
    return DashboardAlertModel(
      id: src['id']?.toString() ?? '',
      title: src['title'] as String? ?? '',
      message: src['message'] as String? ?? '',
      severity: src['severity'] as String? ?? 'medium',
      createdAt: parseApiDateTimeOrNow(src['createdAt']?.toString()),
      referenceTable: src['referenceTable'] as String?,
      referenceId: src['referenceId']?.toString(),
      metricName: src['metricName'] as String?,
      currentValue: (src['currentValue'] as num?)?.toDouble(),
      thresholdValue: (src['thresholdValue'] as num?)?.toDouble(),
    );
  }
}
