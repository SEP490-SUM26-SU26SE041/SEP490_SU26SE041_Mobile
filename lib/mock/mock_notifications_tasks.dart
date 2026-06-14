import 'package:flutter_application_2/shared/widgets/notification_card.dart';
import 'package:flutter_application_2/shared/models/growth_task_model.dart';

final List<NotificationItem> mockNotifications = [
  NotificationItem(
    id: 'notif-001',
    title: 'Cảm biến ngoại tuyến',
    message: 'Cảm biến TEMP-Z01-B02 đã offline hơn 2 giờ. Cần kiểm tra ngay.',
    type: NotificationType.alert,
    severity: AlertSeverity.high,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    linkedRoute: '/farm',
  ),
  NotificationItem(
    id: 'notif-002',
    title: 'Báo cáo task từ Võ Thị Lan',
    message: 'Sinh viên Võ Thị Lan đã hoàn thành "Quan sát tăng trưởng - Ngày 26/4".',
    type: NotificationType.taskUpdate,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    linkedRoute: '/experiments/exp-001',
  ),
  NotificationItem(
    id: 'notif-003',
    title: 'Yêu cầu thực nghiệm được duyệt',
    message: 'Yêu cầu EXP-REQ-003 đã được Farm Manager duyệt. Thực nghiệm mới đã được tạo.',
    type: NotificationType.system,
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    linkedRoute: '/experiments/exp-002',
  ),
  NotificationItem(
    id: 'notif-004',
    title: 'Nhiệt độ vượt ngưỡng',
    message: 'Luống B01-Z01: Nhiệt độ 34.2°C vượt ngưỡng tối đa (32°C). Mức độ: Cao.',
    type: NotificationType.alert,
    severity: AlertSeverity.high,
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    linkedRoute: '/farm',
  ),
];

final List<TaskModel> mockTasks = [
  TaskModel(
    id: 'task-001',
    taskName: 'Quan sát tăng trưởng Nhóm Đối Chứng - Tuần 4',
    taskType: TaskType.observation,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-ctrl-01',
    status: TaskStatus.inProgress,
    assignedTo: 'usr-student-001',
    dueDate: DateTime(2024, 4, 30),
    requiredSkills: const [
      TaskSkillRequirement(skillName: 'Quan sát tăng trưởng', requiredLevel: 2, isMandatory: true),
      TaskSkillRequirement(skillName: 'Ghi chép dữ liệu', requiredLevel: 2, isMandatory: true),
    ],
    aiSuggestion: const AITaskSuggestion(
      suggestedAssigneeId: 'usr-student-001',
      matchScore: 87.5,
      reason: 'Võ Thị Lan có kỹ năng "Quan sát tăng trưởng" level 3 và "Ghi chép dữ liệu" level 4. Hiện có 1 task đang chạy.',
      reviewStatus: 'accepted',
    ),
  ),
  TaskModel(
    id: 'task-002',
    taskName: 'Tưới nhỏ giọt Nhóm Thực Nghiệm - Ngày 15/4→28/4',
    taskType: TaskType.watering,
    experimentId: 'exp-001',
    stageId: 'stage-003',
    batchId: 'batch-trt-01',
    status: TaskStatus.pending,
    assignedTo: null,
    dueDate: DateTime(2024, 4, 28),
    requiredSkills: const [
      TaskSkillRequirement(skillName: 'Tưới tiêu tự động', requiredLevel: 3, isMandatory: true),
      TaskSkillRequirement(skillName: 'Vận hành cảm biến', requiredLevel: 2, isMandatory: false),
    ],
    aiSuggestion: const AITaskSuggestion(
      suggestedAssigneeId: 'usr-technician-001',
      matchScore: 94.2,
      reason: 'Lê Thị Hương có kỹ năng "Tưới tiêu tự động" level 5 và "Vận hành cảm biến" level 4. Hiện có 2 tasks.',
      reviewStatus: 'suggested',
      alternativeCandidates: [
        AICandidateSuggestion(
          userId: 'usr-technician-002',
          fullName: 'Phạm Hoàng Nam',
          matchScore: 71.0,
          currentTaskCount: 3,
          reason: '"Vận hành cảm biến" level 3 nhưng không có kỹ năng "Tưới tiêu tự động". Đang bận hơn.',
        ),
      ],
    ),
  ),
];
