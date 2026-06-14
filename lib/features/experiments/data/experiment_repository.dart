import 'package:flutter_application_2/shared/models/experiment_model.dart';
import 'package:flutter_application_2/mock/mock_experiments.dart';

abstract class ExperimentRepository {
  Future<List<ExperimentModel>> getExperiments();
  Future<ExperimentModel?> getExperiment(String id);
  Future<void> createExperiment(ExperimentModel exp);
}

class MockExperimentRepository implements ExperimentRepository {
  final List<ExperimentModel> _experiments = List.from(mockExperiments);

  @override
  Future<List<ExperimentModel>> getExperiments() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_experiments);
  }

  @override
  Future<ExperimentModel?> getExperiment(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _experiments.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createExperiment(ExperimentModel exp) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _experiments.add(exp);
  }
}
