/// API endpoint constants for SmartFarm backend.
abstract class ApiEndpoints {
  // Auth
  static const login = '/auth/login';

  // Tasks
  static const tasks = '/tasks';
  static const taskMy = '/tasks/my';
  static const taskToday = '/tasks/today';
  static const taskUpcoming = '/tasks/upcoming';
  static const taskOverdue = '/tasks/overdue';

  static String taskById(String id) => '/tasks/$id';
  static String taskSkillMatches(String taskId) => '/tasks/$taskId/skill-matches';
  static String taskAssignments(String taskId) => '/tasks/$taskId/assignments';
  static String taskStart(String taskId) => '/tasks/$taskId/start';
  static String taskComplete(String taskId) => '/tasks/$taskId/complete';
  static String taskCancel(String taskId) => '/tasks/$taskId/cancel';
  static String taskExperiment(String experimentId) => '/tasks/experiment/$experimentId';
  static String researcherCreated({String? scope, String? experimentId, int? upcomingDays}) {
    final params = <String>[];
    if (scope != null) params.add('scope=$scope');
    if (experimentId != null) params.add('experimentId=$experimentId');
    if (upcomingDays != null) params.add('upcomingDays=$upcomingDays');
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return '/tasks/researcher/created$query';
  }

  // Task assignment
  static const taskAssign = '/tasks/assign';
  static const taskReassign = '/tasks/reassign';
  static const myAssignments = '/tasks/assignments/my';

  // Task reports
  static const taskReports = '/task-reports';
  static String taskReportById(String id) => '/task-reports/$id';
  static String taskReportByTask(String taskId) => '/task-reports/task/$taskId';
  static String taskReportByBatch(String batchId) => '/task-reports/batch/$batchId';

  // Task images
  static const taskImages = '/task-images';
  static String taskImageByReport(String reportId) => '/task-images/report/$reportId';
  static String taskImageByBatch(String batchId) => '/task-images/batch/$batchId';

  // Measurement records
  static const measurementRecords = '/measurement-records';
  static const measurementRecordsBulk = '/measurement-records/bulk';
  static String measurementByBatch(String batchId) =>
      '/measurement-records/batch/$batchId';
  static String measurementDefinitionValidate(String definitionId) =>
      '/measurement-definitions/$definitionId/validate';

  // Admin
  static const sweepOverdue = '/tasks/admin/sweep-overdue';

  // Generate tasks
  static String generateByStage(String stageId) => '/tasks/generate-by-stage/$stageId';
  static String generateByExperiment(String experimentId) =>
      '/tasks/generate-by-experiment/$experimentId';

  // ─── Experiments ──────────────────────────────────────────────────────────────

  static const experiments = '/experiments';
  static String experimentById(String id) => '/experiments/$id';
  static String experimentStatus(String id) => '/experiments/$id/status';
  static String experimentDesign(String id) => '/experiments/$id/design';
  static String experimentStages(String id) => '/experiments/$id/stages';
  static String experimentStage(String experimentId, String stageId) =>
      '/experiments/$experimentId/stages/$stageId';
  static String experimentGroups(String id) => '/experiments/$id/groups';
  static String experimentMeasurements(String id) => '/experiments/$id/measurements';
  static String experimentSchedules(String id) => '/experiments/$id/schedules';

  // Stage statistics
  static String stageStatistics(String stageId) =>
      '/experiments/stages/$stageId/statistics';
  static String stageStatisticsExport(String stageId) =>
      '/experiments/stages/$stageId/statistics/export';
  static String experimentStatistics(String experimentId) =>
      '/experiments/$experimentId/statistics';

  // Stages
  static String stageById(String stageId) => '/experiments/stages/$stageId';

  // Batches
  static String batchesByExperiment(String experimentId) =>
      '/batches/experiments/$experimentId';
  static String batchById(String batchId) => '/batches/$batchId';
  static const batches = '/batches';

  // Notifications
  static const notifications = '/Notifications';
  static const notificationsUnreadCount = '/Notifications/unread-count';
  static const notificationsReadAll = '/Notifications/read-all';
  static String notificationById(String id) => '/Notifications/$id';
  static String notificationMarkRead(String id) => '/Notifications/$id/read';

  // Dashboard
  static const dashboardOverview = '/dashboard/overview';
  static const dashboardKpis = '/dashboard/kpis';
  static const dashboardAlerts = '/dashboard/alerts';
  static const dashboardPersonnelPerformance = '/dashboard/personnel/performance';

  // Procedure Templates
  static const procedureTemplates = '/experiments/procedure-templates';
  static String procedureTemplateById(String id) =>
      '/experiments/procedure-templates/$id';
}
