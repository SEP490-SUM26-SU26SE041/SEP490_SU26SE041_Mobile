import '../models/experiment_model.dart';

class ExperimentHelper {
  static String getExperimentCode(String experimentId) {
    if (experimentId.isEmpty) return '—';
    return experimentId.substring(0, experimentId.length.clamp(0, 8)).toUpperCase();
  }

  static String getStageName(String experimentId, String? stageId) {
    if (stageId == null || stageId.isEmpty) return '—';
    return stageId;
  }

  static StageStatus? getStageStatus(String experimentId, String? stageId) {
    return null;
  }

  static String getStageStatusLabel(StageStatus? status) {
    if (status == null) return '—';
    return switch (status) {
      StageStatus.active => 'Active',
      StageStatus.completed => 'Completed',
      StageStatus.upcoming => 'Upcoming',
    };
  }

  static String getBatchLabel(String? batchId) {
    if (batchId == null || batchId.isEmpty) return '—';
    return batchId;
  }

  static String getExperimentTitle(String experimentId) {
    if (experimentId.isEmpty) return '—';
    return experimentId;
  }

  static String getStageProgress(String experimentId, String? stageId) {
    return stageId != null ? '—' : '';
  }

  static ExperimentStage? getStage(String experimentId, String? stageId) {
    return null;
  }
}