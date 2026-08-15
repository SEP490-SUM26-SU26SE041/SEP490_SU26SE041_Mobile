import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/growth_log_view.dart';
import '../providers/technician_growth_providers.dart';

class TechnicianGrowthLogScreen extends ConsumerWidget {
  const TechnicianGrowthLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(effectiveTechnicianGrowthRecordsProvider);
    final batchCodes = ref.watch(availableTechnicianBatchCodesProvider);
    final selectedBatch =
        ref.watch(selectedTechnicianGrowthBatchIdProvider);
    final batchMapAsync = ref.watch(technicianBatchCodeByBatchIdProvider);
    final defMap = ref.watch(technicianGrowthDefinitionsProvider);
    final heightSpots = ref.watch(technicianHeightChartSpotsProvider);
    final leafSpots = ref.watch(technicianLeafCountChartSpotsProvider);

    // Loading state.
    if (recordsAsync.isLoading ||
        batchMapAsync.isLoading ||
        defMap == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Error state.
    if (recordsAsync.hasError) {
      final tt = Theme.of(context).textTheme;
      return Scaffold(
        appBar: AppBar(title: const Text('Nhật ký tăng trưởng')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text('Lỗi tải dữ liệu', style: tt.titleMedium),
              const SizedBox(height: 4),
              Text('${recordsAsync.error}', style: tt.bodySmall),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(technicianGrowthRecordsProvider);
                  ref.invalidate(technicianBatchCodeByBatchIdProvider);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final records = recordsAsync.value ?? const [];
    final batchMap = batchMapAsync.value ?? const <String, String>{};

    return GrowthLogView(
      title: 'Số liệu đo lường (Kỹ thuật)',
      emptyHint:
          'Hãy hoàn thành các task đo lường/bảo trì\nđể dữ liệu hiển thị tại đây.',
      records: records,
      heightSpots: heightSpots,
      leafCountSpots: leafSpots,
      batchCodes: batchCodes,
      selectedBatch: selectedBatch,
      batchMap: batchMap,
      isBatchMapLoading: batchMapAsync.isLoading,
      defMap: defMap,
      onBatchChanged: (code) {
        ref.read(selectedTechnicianGrowthBatchIdProvider.notifier).state =
            code == selectedBatch ? '' : code;
      },
      onRefresh: () {
        ref.invalidate(technicianGrowthRecordsProvider);
        ref.invalidate(technicianBatchCodeByBatchIdProvider);
      },
    );
  }
}
