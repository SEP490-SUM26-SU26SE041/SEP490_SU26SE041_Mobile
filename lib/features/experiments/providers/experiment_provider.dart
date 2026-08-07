import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/experiment_model.dart';
import '../../../shared/widgets/notification_card.dart';
import '../data/experiment_repository.dart';
import '../../../core/api/services/experiment_api_service.dart';
import '../../../core/api/models/batch_model.dart';

final experimentRepositoryProvider = Provider<ExperimentRepository>((ref) {
  return ExperimentRepositoryImpl(ref.read(experimentApiServiceProvider));
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

// ─── Notifications (placeholder — TODO: connect to real notification API) ───

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async {
  // TODO: Replace with real notification API endpoint when backend provides it
  return [];
});

// ─── Separate API Providers for Experiment Detail ───────────────────────────────────

/// Stages from API /experiments/{id}/stages
final experimentStagesProvider = FutureProvider.family<List<ExperimentStage>, String>((ref, experimentId) async {
  final api = ref.read(experimentApiServiceProvider);
  return api.getStages(experimentId);
});

/// Groups from API /experiments/{id}/groups
final experimentGroupsProvider = FutureProvider.family<List<ExperimentGroup>, String>((ref, experimentId) async {
  final api = ref.read(experimentApiServiceProvider);
  return api.getGroups(experimentId);
});

/// Design from API /experiments/{id}/design
final experimentDesignProvider = FutureProvider.family<ExperimentDesign?, String>((ref, experimentId) async {
  final api = ref.read(experimentApiServiceProvider);
  return api.getDesign(experimentId);
});

/// Measurement Definitions from API /experiments/{id}/measurements
final experimentMeasurementsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, experimentId) async {
  final api = ref.read(experimentApiServiceProvider);
  return api.getMeasurementDefinitions(experimentId);
});

/// Batches from API /batches/experiments/{experimentId}
final experimentBatchesProvider = FutureProvider.family<List<BatchModel>, String>((ref, experimentId) async {
  final api = ref.read(experimentApiServiceProvider);
  return api.getBatchesByExperiment(experimentId);
});
