import '../../../shared/models/experiment_model.dart';
import '../../../core/api/services/experiment_api_service.dart';

abstract class ExperimentRepository {
  Future<List<ExperimentModel>> getExperiments();
  Future<ExperimentModel?> getExperiment(String id);
  Future<void> createExperiment(ExperimentModel exp);
}

class ExperimentRepositoryImpl implements ExperimentRepository {
  ExperimentRepositoryImpl(this._api);
  final ExperimentApiService _api;

  @override
  Future<List<ExperimentModel>> getExperiments() async {
    return _api.getExperiments();
  }

  @override
  Future<ExperimentModel?> getExperiment(String id) async {
    return _api.getExperiment(id);
  }

  @override
  Future<void> createExperiment(ExperimentModel exp) async {
    throw UnimplementedError('createExperiment not implemented');
  }
}
