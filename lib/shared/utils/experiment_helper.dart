import '../models/experiment_model.dart';
import '../../mock/mock_experiments.dart';

class ExperimentHelper {
  static String getExperimentCode(String experimentId) {
    try {
      final exp = mockExperiments.firstWhere((e) => e.id == experimentId);
      return exp.experimentCode;
    } catch (_) {
      return 'EXP-???';
    }
  }

  static String getStageName(String experimentId, String? stageId) {
    if (stageId == null) return '—';
    try {
      final exp = mockExperiments.firstWhere((e) => e.id == experimentId);
      final stage = exp.stages.firstWhere((s) => s.id == stageId);
      return stage.stageName;
    } catch (_) {
      return '—';
    }
  }

  static ExperimentStage? getStage(String experimentId, String? stageId) {
    if (stageId == null) return null;
    try {
      final exp = mockExperiments.firstWhere((e) => e.id == experimentId);
      return exp.stages.firstWhere((s) => s.id == stageId);
    } catch (_) {
      return null;
    }
  }

  static StageStatus? getStageStatus(String experimentId, String? stageId) {
    if (stageId == null) return null;
    final stage = getStage(experimentId, stageId);
    return stage?.status;
  }

  static String getStageStatusLabel(StageStatus? status) {
    if (status == null) return '—';
    return switch (status) {
      StageStatus.active    => 'Active',
      StageStatus.completed => 'Completed',
      StageStatus.upcoming  => 'Upcoming',
    };
  }

  static String getBatchLabel(String? batchId) {
    if (batchId == null || batchId.isEmpty) return '—';
    return switch (batchId) {
      'batch-ctrl-01' => 'Đối Chứng (B01)',
      'batch-trt-01' => 'Thực Nghiệm (B02)',
      _ => batchId,
    };
  }

  static String getExperimentTitle(String experimentId) {
    try {
      final exp = mockExperiments.firstWhere((e) => e.id == experimentId);
      return exp.title;
    } catch (_) {
      return '—';
    }
  }

  static String getStageProgress(String experimentId, String? stageId) {
    final stage = getStage(experimentId, stageId);
    if (stage == null) return '';
    return switch (stage.status) {
      StageStatus.active    => 'Đang chạy',
      StageStatus.completed => 'Hoàn thành',
      StageStatus.upcoming  => 'Sắp tới',
      _ => stage.stageName,
    };
  }
}
