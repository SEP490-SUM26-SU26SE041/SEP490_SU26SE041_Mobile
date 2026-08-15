import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/models/growth_task_model.dart';

final selectedBatchIdProvider = StateProvider<String>((ref) => '');

final filteredGrowthRecordsProvider = Provider<List<GrowthRecordModel>>((ref) {
  return [];
});

final chartDataProvider = Provider<List<FlSpot>>((ref) {
  return [];
});

final hasTodayRecordProvider = Provider<bool>((ref) => false);

final observationCountProvider = Provider<int>((ref) => 0);
