import '../shared/models/experiment_model.dart';

final mockExperiments = [
  ExperimentModel(
    id: 'exp-001',
    experimentCode: 'EXP-2024-001',
    title: 'So sánh phương pháp tưới nhỏ giọt và tưới phun sương trên cà chua bi',
    objective: 'Xác định phương pháp tưới tối ưu nhằm tăng tỷ lệ sống và chiều cao cây cà chua bi trong giai đoạn vườn ươm 45 ngày đầu.',
    status: ExperimentStatus.active,
    researcherId: 'usr-researcher-001',
    startDate: DateTime(2024, 3, 1),
    endDate: DateTime(2024, 5, 15),
    cropVariety: 'Cà chua bi Cherry 101',
    design: const ExperimentDesign(
      designType: DesignType.completelyRandomized,
      sampleSize: 60,
      replicationCount: 3,
      treatmentCount: 2,
      observationFrequencyDays: 2,
      measurementFrequencyDays: 7,
      evaluationCriteria: 'Chiều cao cây, số lá, tỷ lệ sống, chỉ số SPAD chlorophyll',
      analysisPlan: 'ANOVA một nhân tố, so sánh Tukey HSD, p < 0.05',
    ),
    groups: const [
      ExperimentGroup(
        id: 'grp-control-001',
        groupName: 'Nhóm Đối Chứng',
        groupType: GroupType.control,
        description: 'Tưới phun sương 2 lần/ngày, 200ml/lần',
        sampleSize: 30,
        cultivationMethod: CultivationMethod(
          methodName: 'Tưới phun sương truyền thống',
          wateringRule: WateringRule(amount: 200, frequencyDays: 1),
          fertilizingRule: FertilizingRule(
            fertilizerName: 'NPK 20-20-20',
            amount: 5.0,
            frequencyDays: 7,
          ),
        ),
      ),
      ExperimentGroup(
        id: 'grp-treatment-001',
        groupName: 'Nhóm Thực Nghiệm',
        groupType: GroupType.treatment,
        description: 'Tưới nhỏ giọt liên tục 4h/ngày, sensor-controlled',
        sampleSize: 30,
        cultivationMethod: CultivationMethod(
          methodName: 'Tưới nhỏ giọt IoT',
          wateringRule: WateringRule(amount: 150, frequencyDays: 1),
          fertilizingRule: FertilizingRule(
            fertilizerName: 'Fert-Plus Hữu Cơ',
            amount: 4.0,
            frequencyDays: 7,
          ),
        ),
      ),
    ],
    stages: [
      ExperimentStage(
        id: 'stage-001',
        stageOrder: 1,
        stageName: 'Giai Đoạn Vườn Ươm',
        stageType: ExperimentStageType.nursery,
        startDate: DateTime(2024, 3, 1),
        endDate: DateTime(2024, 3, 21),
        status: StageStatus.completed,
        result: const StageResult(
          summary: 'Tỷ lệ nảy mầm: Đối chứng 82%, Thực nghiệm 88%. Nhóm thực nghiệm cho tỷ lệ cao hơn 6%.',
        ),
      ),
      ExperimentStage(
        id: 'stage-002',
        stageOrder: 2,
        stageName: 'Giai Đoạn Chăm Sóc',
        stageType: ExperimentStageType.care,
        startDate: DateTime(2024, 3, 22),
        endDate: DateTime(2024, 4, 15),
        status: StageStatus.completed,
        result: const StageResult(
          summary: 'Nhóm thực nghiệm cao hơn trung bình 1.4cm sau 3 tuần chăm sóc.',
        ),
      ),
      ExperimentStage(
        id: 'stage-003',
        stageOrder: 3,
        stageName: 'Giai Đoạn Tăng Trưởng',
        stageType: ExperimentStageType.growth,
        startDate: DateTime(2024, 4, 16),
        endDate: DateTime(2024, 5, 5),
        status: StageStatus.active,
      ),
      ExperimentStage(
        id: 'stage-004',
        stageOrder: 4,
        stageName: 'Thu Hoạch',
        stageType: ExperimentStageType.harvest,
        startDate: DateTime(2024, 5, 6),
        endDate: DateTime(2024, 5, 10),
        status: StageStatus.upcoming,
      ),
      ExperimentStage(
        id: 'stage-005',
        stageOrder: 5,
        stageName: 'Đánh Giá Tổng Kết',
        stageType: ExperimentStageType.evaluation,
        startDate: DateTime(2024, 5, 11),
        endDate: DateTime(2024, 5, 15),
        status: StageStatus.upcoming,
      ),
    ],
  ),
];

ExperimentModel? getExperimentById(String id) {
  try {
    return mockExperiments.firstWhere((e) => e.id == id);
  } catch (_) {
    return null;
  }
}
