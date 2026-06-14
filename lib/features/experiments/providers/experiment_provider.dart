import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/experiment_model.dart';
import '../../../shared/models/growth_task_model.dart';
import '../../../shared/widgets/notification_card.dart';
import '../data/experiment_repository.dart';

final experimentRepositoryProvider = Provider<ExperimentRepository>((ref) {
  return MockExperimentRepository();
});

final experimentsProvider = FutureProvider<List<ExperimentModel>>((ref) async {
  final repo = ref.read(experimentRepositoryProvider);
  return repo.getExperiments();
});

final experimentDetailProvider = FutureProvider.family<ExperimentModel?, String>((ref, id) async {
  final repo = ref.read(experimentRepositoryProvider);
  return repo.getExperiment(id);
});

final experimentFilterProvider = StateProvider<ExperimentFilter>((ref) {
  return const ExperimentFilter();
});

class ExperimentFilter {
  const ExperimentFilter({this.status, this.searchQuery});
  final ExperimentStatus? status;
  final String? searchQuery;
}

final filteredExperimentsProvider = Provider<AsyncValue<List<ExperimentModel>>>((ref) {
  final experiments = ref.watch(experimentsProvider);
  final filter = ref.watch(experimentFilterProvider);

  return experiments.whenData((list) {
    var filtered = list;

    if (filter.status != null) {
      filtered = filtered.where((e) => e.status == filter.status).toList();
    }

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final q = filter.searchQuery!.toLowerCase();
      filtered = filtered.where((e) =>
        e.title.toLowerCase().contains(q) ||
        e.experimentCode.toLowerCase().contains(q) ||
        e.cropVariety.toLowerCase().contains(q)
      ).toList();
    }

    return filtered;
  });
});

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return _mockNotifications;
});

final tasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return _mockTasks;
});

final List<NotificationItem> _mockNotifications = [
  NotificationItem(
    id: 'notif-001',
    title: 'Cam bien ngoai tuyen',
    message: 'Cam bien TEMP-Z01-B02 da offline hon 2 gio. Can kiem tra ngay.',
    type: NotificationType.alert,
    severity: AlertSeverity.high,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    linkedRoute: '/farm',
  ),
  NotificationItem(
    id: 'notif-002',
    title: 'Bao cao task tu Vo Thi Lan',
    message: 'Sinh vien Vo Thi Lan da hoan thanh "Quan sat tang truong - Ngay 26/4".',
    type: NotificationType.taskUpdate,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    linkedRoute: '/experiments/exp-001',
  ),
  NotificationItem(
    id: 'notif-003',
    title: 'Yeu cau thuc nghiem duoc duyet',
    message: 'Yeu cau EXP-REQ-003 da duoc Farm Manager duyet. Thuc nghiem moi da duoc tao.',
    type: NotificationType.system,
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    linkedRoute: '/experiments/exp-002',
  ),
  NotificationItem(
    id: 'notif-004',
    title: 'Nhiet do vuot nguong',
    message: 'Luong B01-Z01: Nhiet do 34.2C vuot nguong toi da (32C). Muc do: Cao.',
    type: NotificationType.alert,
    severity: AlertSeverity.high,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    linkedRoute: '/farm',
  ),
];

final List<TaskModel> _mockTasks = [
  TaskModel(
    id: 'task-001',
    taskName: 'Quan sat tang truong Nhom Doi Chung - Tuan 4',
    taskType: TaskType.observation,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-ctrl-01',
    status: TaskStatus.inProgress,
    assignedTo: 'usr-student-001',
    dueDate: DateTime(2024, 4, 30),
    requiredSkills: const [
      TaskSkillRequirement(skillName: 'Quan sat tang truong', requiredLevel: 2, isMandatory: true),
      TaskSkillRequirement(skillName: 'Ghi chep du lieu', requiredLevel: 2, isMandatory: true),
    ],
    aiSuggestion: const AITaskSuggestion(
      suggestedAssigneeId: 'usr-student-001',
      matchScore: 87.5,
      reason: 'Vo Thi Lan co ky nang phu hop. Hien co 1 task dang chay.',
      reviewStatus: 'accepted',
    ),
  ),
  TaskModel(
    id: 'task-002',
    taskName: 'Tuoi nho giot Nhom Thuc Nghiem',
    taskType: TaskType.watering,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-trt-01',
    status: TaskStatus.pending,
    assignedTo: null,
    dueDate: DateTime(2024, 4, 28),
    requiredSkills: const [
      TaskSkillRequirement(skillName: 'Tuoi tieu tu dong', requiredLevel: 3, isMandatory: true),
    ],
    aiSuggestion: const AITaskSuggestion(
      suggestedAssigneeId: 'usr-technician-001',
      matchScore: 94.2,
      reason: 'Le Thi Huong co ky nang phu hop. Hien co 2 tasks.',
      reviewStatus: 'suggested',
    ),
  ),
];
