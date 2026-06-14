class GrowthRecordModel {
  const GrowthRecordModel({
    required this.id,
    required this.batchId,
    required this.recordedBy,
    required this.recordedAt,
    required this.plantHeight,
    required this.leafCount,
    required this.leafColor,
    required this.plantStatus,
    this.note,
    this.imageUrl,
  });

  final String id;
  final String batchId;
  final String recordedBy;
  final DateTime recordedAt;
  final double plantHeight;
  final int leafCount;
  final String leafColor;
  final String plantStatus;
  final String? note;
  final String? imageUrl;
}

class CareScheduleModel {
  const CareScheduleModel({
    required this.id,
    required this.batchId,
    required this.scheduleType,
    required this.scheduledAt,
    required this.status,
    this.performedAt,
    this.waterAmount,
    this.fertilizerAmount,
    this.note,
  });

  final String id;
  final String batchId;
  final String scheduleType;
  final DateTime scheduledAt;
  final String status;
  final DateTime? performedAt;
  final double? waterAmount;
  final double? fertilizerAmount;
  final String? note;
}

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
    this.messages = const [],
  });

  final String id;
  final String title;
  final String lastMessage;
  final DateTime updatedAt;
  final List<ConversationMessage> messages;
}

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
}

final mockGrowthRecords = [
  GrowthRecordModel(
    id: 'gr-001',
    batchId: 'batch-ctrl-01',
    recordedBy: 'usr-student-001',
    recordedAt: DateTime.now().subtract(const Duration(days: 1)),
    plantHeight: 18.5,
    leafCount: 8,
    leafColor: 'Xanh đậm',
    plantStatus: 'Khỏe mạnh',
    note: 'Cây phát triển tốt, không có dấu hiệu sâu bệnh.',
  ),
  GrowthRecordModel(
    id: 'gr-002',
    batchId: 'batch-ctrl-01',
    recordedBy: 'usr-student-001',
    recordedAt: DateTime.now().subtract(const Duration(days: 3)),
    plantHeight: 16.2,
    leafCount: 7,
    leafColor: 'Xanh đậm',
    plantStatus: 'Khỏe mạnh',
  ),
  GrowthRecordModel(
    id: 'gr-003',
    batchId: 'batch-ctrl-01',
    recordedBy: 'usr-student-002',
    recordedAt: DateTime.now().subtract(const Duration(days: 5)),
    plantHeight: 14.1,
    leafCount: 6,
    leafColor: 'Xanh',
    plantStatus: 'Khỏe mạnh',
  ),
];

final mockCareSchedules = [
  CareScheduleModel(
    id: 'cs-001',
    batchId: 'batch-ctrl-01',
    scheduleType: 'Watering',
    scheduledAt: DateTime.now().subtract(const Duration(hours: 2)),
    status: 'completed',
    performedAt: DateTime.now().subtract(const Duration(hours: 2)),
    waterAmount: 200,
  ),
  CareScheduleModel(
    id: 'cs-002',
    batchId: 'batch-trt-01',
    scheduleType: 'Watering',
    scheduledAt: DateTime.now(),
    status: 'pending',
    waterAmount: 150,
  ),
  CareScheduleModel(
    id: 'cs-003',
    batchId: 'batch-ctrl-01',
    scheduleType: 'Fertilizing',
    scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
    status: 'completed',
    performedAt: DateTime.now().subtract(const Duration(days: 1)),
    waterAmount: 200,
    fertilizerAmount: 5.0,
    note: 'Bón NPK 20-20-20, 5g/cây.',
  ),
];

final mockConversations = [
  ConversationModel(
    id: 'conv-001',
    title: 'Về giống cà chua',
    lastMessage: 'Bạn có thể tư vấn thêm về giống cà chua bi Cherry không?',
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    messages: [
      ConversationMessage(id: 'msg-001', role: 'user', content: 'Xin chào, tôi muốn hỏi về giống cà chua bi Cherry.', timestamp: DateTime.now()),
      ConversationMessage(id: 'msg-002', role: 'assistant', content: 'Cà chua bi Cherry 101 phù hợp với nhiệt độ 22-28°C, độ ẩm 60-70%.', timestamp: DateTime.now()),
    ],
  ),
  ConversationModel(
    id: 'conv-002',
    title: 'Phương pháp tưới',
    lastMessage: 'Tưới nhỏ giọt có tiết kiệm nước không?',
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    messages: const [],
  ),
];
