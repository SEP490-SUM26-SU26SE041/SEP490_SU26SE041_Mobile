enum ExperimentStatus { draft, planning, pending, active, completed, paused }

enum ExperimentStageType { nursery, care, growth, harvest, evaluation }

enum StageStatus { upcoming, active, completed }

enum GroupType { control, treatment }

enum DesignType { completelyRandomized, randomizedBlock, factorial }

class WateringRule {
  const WateringRule({required this.amount, required this.frequencyDays});
  final int amount;
  final int frequencyDays;
}

class FertilizingRule {
  const FertilizingRule({
    required this.fertilizerName,
    required this.amount,
    required this.frequencyDays,
  });
  final String fertilizerName;
  final double amount;
  final int frequencyDays;
}

class CultivationMethod {
  const CultivationMethod({
    required this.methodName,
    required this.wateringRule,
    required this.fertilizingRule,
  });
  final String methodName;
  final WateringRule wateringRule;
  final FertilizingRule fertilizingRule;
}

class ExperimentGroup {
  const ExperimentGroup({
    required this.id,
    required this.groupName,
    required this.groupType,
    this.description,
    required this.cultivationMethod,
    this.sampleSize = 30,
  });
  final String id;
  final String groupName;
  final GroupType groupType;
  final String? description;
  final CultivationMethod cultivationMethod;
  final int sampleSize;
}

class ExperimentDesign {
  const ExperimentDesign({
    required this.id,
    required this.designType,
    required this.replicationCount,
    required this.randomizationMethod,
    this.designParameters,
  });
  final String id;
  final String designType;
  final int replicationCount;
  final String randomizationMethod;
  final DesignParameters? designParameters;

  String get designTypeLabel {
    if (designType.contains('CRD') || designType == 'CRD') return 'CRD';
    if (designType.contains('RCBD') || designType == 'RCBD') return 'RCBD';
    if (designType.contains('Factorial')) return 'Factorial';
    return designType;
  }
}

class DesignParameters {
  const DesignParameters({
    this.notes,
    this.layout,
    this.spacing,
    this.plotArea,
    this.plotWidth,
    this.blockCount,
    this.bufferZone,
    this.plotLength,
    this.randomSeed,
    this.treatments,
    this.plantsPerPlot,
  });
  final String? notes;
  final String? layout;
  final PlotSpacing? spacing;
  final int? plotArea;
  final double? plotWidth;
  final int? blockCount;
  final String? bufferZone;
  final double? plotLength;
  final int? randomSeed;
  final int? treatments;
  final int? plantsPerPlot;
}

class PlotSpacing {
  const PlotSpacing({this.row, this.plant});
  final String? row;
  final String? plant;
}

class StageResult {
  const StageResult({required this.summary, this.metrics});
  final String summary;
  final Map<String, double>? metrics;
}

class ExperimentStage {
  const ExperimentStage({
    required this.id,
    required this.stageOrder,
    required this.stageName,
    required this.stageType,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.result,
  });
  final String id;
  final int stageOrder;
  final String stageName;
  final ExperimentStageType stageType;
  final DateTime startDate;
  final DateTime endDate;
  final StageStatus status;
  final StageResult? result;

  String get stageTypeLabel => switch (stageType) {
    ExperimentStageType.nursery    => 'Vườn Ươm',
    ExperimentStageType.care       => 'Chăm Sóc',
    ExperimentStageType.growth     => 'Tăng Trưởng',
    ExperimentStageType.harvest    => 'Thu Hoạch',
    ExperimentStageType.evaluation => 'Đánh Giá',
  };

  int get statusColorValue => switch (status) {
    StageStatus.upcoming   => 0xFF90A4AE,
    StageStatus.active     => 0xFF4CAF50,
    StageStatus.completed => 0xFF42A5F5,
  };
}

class ExperimentModel {
  const ExperimentModel({
    required this.id,
    required this.experimentCode,
    required this.title,
    required this.objective,
    required this.status,
    required this.researcherId,
    required this.startDate,
    required this.endDate,
    required this.cropVariety,
    required this.design,
    required this.groups,
    required this.stages,
    this.requiredArea,
    this.plantQuantity,
  });
  final String id;
  final String experimentCode;
  final String title;
  final String objective;
  final ExperimentStatus status;
  final String researcherId;
  final DateTime startDate;
  final DateTime endDate;
  final String cropVariety;
  final ExperimentDesign design;
  final List<ExperimentGroup> groups;
  final List<ExperimentStage> stages;
  final double? requiredArea;
  final int? plantQuantity;

  ExperimentStage? get activeStage {
    if (stages.isEmpty) return null;
    for (final stage in stages) {
      if (stage.status == StageStatus.active) return stage;
    }
    return null;
  }

  double get progress {
    if (stages.isEmpty) return 0.0;
    final completed = stages.where((s) => s.status == StageStatus.completed).length;
    final p = completed / stages.length;
    if (p.isNaN || p.isInfinite) return 0.0;
    return p;
  }
}
