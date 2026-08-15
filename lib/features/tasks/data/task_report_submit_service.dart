import 'dart:io';

import '../../../core/api/models/measurement_record_model.dart';
import '../../../core/api/models/task_report_model.dart';
import '../../../core/api/services/measurement_record_api_service.dart';
import '../data/measurement_bridge.dart';
import '../data/task_image_repository.dart';
import '../providers/task_report_providers.dart' as rp;
import '../providers/task_providers.dart' as tp;
import '../providers/measurement_record_providers.dart' as mp;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service tổng hợp luồng submit report theo `TASK_REPORT_BRIDGE_FLOW.md`.
///
/// Orchestrate theo 5 bước:
///   1. Build payload (ReportResultData map + list ảnh).
///   2. POST /task-reports      → lấy `reportId`.
///   3. POST /measurement-records/bulk HOẶC /measurement-records ×N.
///   4. POST /task-images/upload (multipart, song song `Promise.allSettled`).
///   5. PATCH /tasks/{id}/complete (optional).
///
/// Không tự gọi API — tất cả qua `ref.read(...).future`. Cho phép unit-test
/// với mock providers.
class TaskReportSubmitService {
  TaskReportSubmitService(this.ref);
  final Ref ref;

  /// Kết quả tổng.
  Future<SubmitOutcome> submitAndOptionallyComplete(SubmitParams params) async {
    final errors = <String>[];
    int measurementCount = 0;
    int imageCount = 0;
    int imageFailures = 0;

    String? reportId;

    // 1. Submit TaskReport (nếu có content mới)
    if (params.hasNewContent) {
      try {
        final dto = CreateTaskReportDto(
          taskId: params.taskId,
          reportText: params.reportText,
          resultData: params.resultData,
        );
        final report = await ref.read(rp.submitReportProvider(dto).future);
        reportId = report.id;
      } catch (e) {
        errors.add('Tạo TaskReport thất bại: $e');
        return SubmitOutcome(
          mode: SubmitMode.error,
          reportId: null,
          measurementCount: 0,
          imageCount: 0,
          errors: errors,
        );
      }
    } else if (params.fallbackReportId != null) {
      reportId = params.fallbackReportId;
    }

    // 2. Bridge: tạo MeasurementRecords (nếu có data + ids)
    if (params.effectiveDefinitions != null &&
        params.bridgeOutput != null &&
        params.bridgeOutput!.isNotEmpty) {
      try {
        if (params.bridgeOutput!.path == BridgePath.bulk &&
            params.bridgeOutput!.bulk != null) {
          final b = params.bridgeOutput!.bulk!;
          final bulkDto = BulkMeasurementDto(
            experimentId: b.experimentId,
            experimentStageId: b.experimentStageId ?? '',
            batchId: b.batchId,
            measuredAt: b.measuredAt,
            extraData: b.extraData,
            items: b.items
                .map((i) => BulkMeasurementItem(
                      measurementDefinitionId: i.definitionId,
                      value: i.value,
                    ))
                .toList(),
          );
          final resp = await ref.read(mp.bulkMeasurementProvider(bulkDto).future);
          measurementCount = resp.created;
          if (resp.skipped > 0) errors.add('Bỏ qua ${resp.skipped} chỉ số');
        } else if (params.bridgeOutput!.path == BridgePath.legacy) {
          // Legacy: gọi song song, không fail cả batch.
          final futures = params.bridgeOutput!.singles.map((s) async {
            try {
              await ref.read(measurementRecordApiServiceProvider).createRecord(
                    experimentId: s.experimentId,
                    experimentStageId: s.experimentStageId ?? '',
                    batchId: s.batchId ?? '',
                    measurementDefinitionId: s.measurementDefinitionId ?? '',
                    value: s.value,
                    measuredAt: s.measuredAt,
                  );
              return 1;
            } catch (_) {
              return 0;
            }
          }).toList();
          final results = await Future.wait(futures);
          measurementCount = results.fold(0, (a, b) => a + b);
        }
      } catch (e) {
        errors.add('Bridge measurement lỗi: $e');
      }
    }

    // 3. Upload ảnh (Promise.allSettled — không fail cả batch)
    if (params.images.isNotEmpty && reportId != null) {
      final uploader = ref.read(taskImageRepositoryProvider);
      final reportIdValue = reportId; // Đã null-check ở dòng 112
      final results = await Future.wait(params.images.map((img) async {
        try {
          if (img.file != null) {
            await uploader.uploadTaskImage(
              experimentId: params.experimentId ?? '',
              batchId: params.batchId ?? '',
              taskReportId: reportIdValue,
              taskId: params.taskId,
              imageFile: img.file!,
              caption: img.caption,
              capturedAt: img.uploadedAt,
              imageUrl: img.imageUrl,
            );
            return true;
          }
          if (img.imageUrl != null) {
            await uploader.attachExistingImageUrl(
              experimentId: params.experimentId ?? '',
              batchId: params.batchId ?? '',
              taskReportId: reportIdValue,
              imageUrl: img.imageUrl!,
              caption: img.caption,
              capturedAt: img.uploadedAt,
            );
            return true;
          }
          return false;
        } catch (_) {
          return false;
        }
      }));
      for (final ok in results) {
        if (ok) {
          imageCount++;
        } else {
          imageFailures++;
        }
      }
      if (imageFailures > 0) {
        errors.add('Upload $imageFailures ảnh thất bại');
      }
    }

    // 4. Complete task (optional)
    if (params.markComplete) {
      try {
        await ref.read(tp.completeTaskProvider(params.taskId).future);
      } catch (e) {
        errors.add('Hoàn thành task thất bại: $e');
      }
    }

    return SubmitOutcome(
      mode: errors.isEmpty ? SubmitMode.success : SubmitMode.partial,
      reportId: reportId,
      measurementCount: measurementCount,
      imageCount: imageCount,
      errors: errors,
    );
  }
}

enum SubmitMode { success, partial, error }

class SubmitOutcome {
  const SubmitOutcome({
    required this.mode,
    required this.reportId,
    required this.measurementCount,
    required this.imageCount,
    this.errors = const [],
  });

  final SubmitMode mode;
  final String? reportId;
  final int measurementCount;
  final int imageCount;
  final List<String> errors;

  String toUserMessage() {
    switch (mode) {
      case SubmitMode.success:
        if (measurementCount > 0 && imageCount > 0) {
          return 'Đã hoàn thành! 📊 $measurementCount chỉ số · 📷 $imageCount ảnh';
        }
        if (measurementCount > 0) return 'Đã hoàn thành! 📊 $measurementCount chỉ số';
        if (imageCount > 0) return 'Đã hoàn thành! 📷 $imageCount ảnh';
        return 'Đã hoàn thành!';
      case SubmitMode.partial:
        return 'Hoàn thành một phần: ${errors.first}';
      case SubmitMode.error:
        return 'Thất bại: ${errors.first}';
    }
  }
}

class SubmitParams {
  const SubmitParams({
    required this.taskId,
    required this.reportText,
    required this.resultData,
    required this.images,
    this.experimentId,
    this.batchId,
    this.effectiveDefinitions,
    this.bridgeOutput,
    this.markComplete = true,
    this.hasNewContent = true,
    this.fallbackReportId,
  });

  final String taskId;
  final String reportText;
  final Map<String, String>? resultData;
  final List<TaskReportImageParam> images;
  final String? experimentId;
  final String? batchId;
  final List<dynamic>? effectiveDefinitions; // MeasurementDefinitionModel list
  final BridgeOutput? bridgeOutput;
  final bool markComplete;
  final bool hasNewContent;
  final String? fallbackReportId;
}

/// Param ảnh thuần (FE-driven).
class TaskReportImageParam {
  const TaskReportImageParam({
    this.file,
    this.imageUrl,
    this.caption,
    this.uploadedAt,
  });

  /// File binary (multipart) nếu user vừa chụp/chọn.
  final File? file;

  /// URL (Cloudinary) nếu ảnh đã được upload sẵn.
  final String? imageUrl;

  final String? caption;
  final DateTime? uploadedAt;
}

final taskReportSubmitServiceProvider =
    Provider<TaskReportSubmitService>((ref) => TaskReportSubmitService(ref));
