library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/models/task_report_model.dart';
import '../../../core/api/services/task_image_api_service.dart';
import '../data/task_image_repository.dart';

final taskImageRepositoryProvider = Provider<TaskImageRepository>((ref) {
  return TaskImageRepository(ref.read(taskImageApiServiceProvider));
});

// ─── Get images by report ───────────────────────────────────────────────

final taskImagesByReportProvider = FutureProvider.autoDispose.family<List<TaskImageModel>, String>(
  (ref, reportId) async {
    return ref.read(taskImageRepositoryProvider).getImagesByReport(reportId);
  },
);

// ─── Get images by batch ────────────────────────────────────────────────

final taskImagesByBatchProvider = FutureProvider.autoDispose.family<List<TaskImageModel>, String>(
  (ref, batchId) async {
    return ref.read(taskImageRepositoryProvider).getImagesByBatch(batchId);
  },
);

// ─── Upload image ──────────────────────────────────────────────────────

final uploadTaskImageProvider = FutureProvider.autoDispose.family<TaskImageModel, UploadTaskImageDto>(
  (ref, dto) async {
    return ref.read(taskImageRepositoryProvider).uploadImage(dto);
  },
);
