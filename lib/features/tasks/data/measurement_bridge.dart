library;

import 'package:flutter/foundation.dart';
import '../../../core/api/models/measurement_definition_model.dart';
import '../../../core/api/models/task_model.dart' as api;
import 'task_report_constants.dart';

/// ─── Measurement Bridge ────────────────────────────────────────────────────
///
/// Port y hệt phiên bản JS trong `measurementBridge.js` (xem
/// `TASK_REPORT_BRIDGE_FLOW.md` mục 4–6). Tất cả pure-Dart, không phụ thuộc
/// Riverpod/Dio. Cho phép dễ test với `flutter test`.
///
/// Tóm tắt logic:
///   - Filter definitions theo `groupId` của batch (quan trọng: mỗi nhóm có
///     targetValue riêng cho cùng 1 metricName).
///   - Bulk path: dùng cho `Measurement`/`Observation` task. Key trong
///     resultData là `def_<uuid>` → gom thành `items[]` cho POST /measurement-records/bulk.
///   - Legacy path: task khác. Extract các key có trong `MEASUREMENT_FIELD_MAP`
///     → POST /measurement-records từng cái.

/// Snapshot result của 1 lần gửi report (cho UI hiển thị toast).
class BridgeOutcome {
  const BridgeOutcome({
    required this.mode,
    required this.measurementCount,
    this.skipped = 0,
    this.warnings = const [],
  });

  /// Loại bridge path đã dùng.
  final BridgeMode mode;

  /// Số MeasurementRecord đã tạo thành công.
  final int measurementCount;

  /// Bulk path: số item bị skip.
  final int skipped;

  /// Warning strings (vd: "definition not found").
  final List<String> warnings;

  bool get hasMeasurements => measurementCount > 0;

  @override
  String toString() =>
      'BridgeOutcome(mode=$mode, created=$measurementCount, skipped=$skipped, warnings=${warnings.length})';
}

enum BridgeMode { bulk, legacy, skipped, error }

// ─── Filter definitions ─────────────────────────────────────────────────────

/// Lọc definitions theo groupId của task (lấy theo thứ tự ưu tiên).
///
/// Thứ tự ưu tiên cho `taskGroupId`:
///   1. `explicitGroupId` (lấy từ `GET /batches/{batchId}`).
///   2. `task.batch.groupId` (BE populate).
///   3. `task.batchGroupId` (flat).
///   4. `task.groupId` (flat).
///   5. Fallback: KHÔNG filter — trả về tất cả definitions.
List<MeasurementDefinitionModel> filterDefinitionsByTaskGroup(
  List<MeasurementDefinitionModel> definitions,
  TaskGroupContext task, {
  String? explicitGroupId,
}) {
  if (definitions.isEmpty) return const [];

  final taskGroupId = explicitGroupId ?? task.batchGroupId;
  
  // Nếu có groupId cụ thể, thử lọc theo group đó
  if (taskGroupId != null && taskGroupId.isNotEmpty) {
    final same = definitions.where((d) => d.groupId == taskGroupId).toList();
    if (same.isNotEmpty) {
      debugPrint('[DEBUG] Filter: Found ${same.length} definitions for groupId=$taskGroupId');
      return same;
    }
    debugPrint('[DEBUG] Filter: No definitions match groupId=$taskGroupId, returning all ${definitions.length}');
    // Fallback: trả về tất cả thay vì dedupe
    return definitions;
  }

  // Không có groupId constraint, trả về tất cả (dedupe để tránh trùng metricName)
  debugPrint('[DEBUG] Filter: No groupId constraint, returning all ${definitions.length} definitions');
  final seen = <String>{};
  final dedup = <MeasurementDefinitionModel>[];
  for (final d in definitions) {
    final key = d.metricName.trim().toLowerCase();
    if (key.isEmpty || seen.contains(key)) continue;
    seen.add(key);
    dedup.add(d);
  }
  return dedup;
}

/// Context tối thiểu cần để filter / extract / build — không phụ thuộc
/// `api.TaskModel` để dễ test.
class TaskGroupContext {
  const TaskGroupContext({
    this.experimentId,
    this.experimentStageId,
    this.batchId,
    this.batchGroupId,
    this.taskType,
  });

  final String? experimentId;
  final String? experimentStageId;
  final String? batchId;
  final String? batchGroupId;
  final api.TaskType? taskType;

  factory TaskGroupContext.fromTaskModel(api.TaskModel m) => TaskGroupContext(
        experimentId: m.experimentId.isEmpty ? null : m.experimentId,
        experimentStageId: m.experimentStageId,
        batchId: m.batchId,
        batchGroupId: null, // cần fetch từ batch.api.getById(batchId)
        taskType: m.taskType,
      );
}

// ─── Fetch batch group info ─────────────────────────────────────────────────

/// Kết quả fetch batch — chỉ lấy field quan trọng nhất.
class BatchGroupInfo {
  const BatchGroupInfo({
    required this.batchId,
    required this.groupId,
    required this.groupName,
    this.batchCode,
  });

  final String batchId;
  final String? groupId;
  final String groupName;
  final String? batchCode;

  /// API giả: gọi backend thật, sử dụng `BatchRepository` ở layer ngoài.
  /// Hàm này làm "demo API" — FE tự fetch qua provider.
  static Future<BatchGroupInfo?> Function(String batchId)? fetcher;
}

// ─── Extract bulk items (def_<uuid>) ────────────────────────────────────────

class BulkItem {
  const BulkItem({
    required this.definitionId,
    required this.value,
    this.metricName,
    this.unit,
    this.targetValue,
  });

  final String definitionId;
  final double value;
  final String? metricName;
  final String? unit;
  final double? targetValue;
}

/// Chuyển `resultData` thành `BulkItem[]` cho POST /measurement-records/bulk.
List<BulkItem> extractBulkItemsFromResultData(
  Map<String, dynamic> resultData,
  List<MeasurementDefinitionModel> definitions,
) {
  final byId = {for (final d in definitions) d.id: d};
  final items = <BulkItem>[];
  for (final entry in resultData.entries) {
    final key = entry.key;
    if (!key.startsWith('def_')) continue;
    final defId = key.substring(4);
    if (defId.isEmpty) continue;
    final raw = entry.value;
    if (raw == null) continue;
    final s = raw.toString().trim();
    if (s.isEmpty) continue;
    final num = double.tryParse(s.replaceAll(',', '.'));
    if (num == null) continue;

    final def = byId[defId];
    items.add(BulkItem(
      definitionId: defId,
      value: num,
      metricName: def?.metricName,
      unit: def?.unit,
      targetValue: def?.targetValue,
    ));
  }
  return items;
}

// ─── Extract measurements (legacy MEASUREMENT_FIELD_MAP) ────────────────────

class LegacyMeasurementItem {
  const LegacyMeasurementItem({
    required this.name,
    required this.value,
    required this.unit,
    required this.description,
    required this.sourceKey,
  });

  final String name;
  final double value;
  final String unit;
  final String description;
  final String sourceKey;
}

/// Tìm trong `resultData` các key nằm trong `kMeasurementFieldMap` và build
/// list measurements legacy.
List<LegacyMeasurementItem> extractMeasurementsFromReport(
  Map<String, dynamic> resultData,
) {
  final out = <LegacyMeasurementItem>[];
  for (final entry in resultData.entries) {
    final mapping = kMeasurementFieldMap[entry.key];
    if (mapping == null) continue;
    final raw = entry.value;
    if (raw == null) continue;
    final s = raw.toString().trim();
    if (s.isEmpty) continue;
    final n = double.tryParse(s.replaceAll(',', '.'));
    if (n == null) continue;

    out.add(LegacyMeasurementItem(
      name: mapping.targetName,
      value: n,
      unit: mapping.targetUnit,
      description: mapping.description,
      sourceKey: entry.key,
    ));
  }
  return out;
}

// ─── Build payloads ─────────────────────────────────────────────────────────

/// Tham số phụ cho payload (extraData).
class BridgeExtraMeta {
  const BridgeExtraMeta({this.measuredAt, this.notes, this.textValue});
  final DateTime? measuredAt;
  final String? notes;
  final String? textValue;
}

/// Payload cho legacy POST /measurement-records.
class SingleMeasurementPayload {
  const SingleMeasurementPayload({
    required this.experimentId,
    this.experimentStageId,
    this.batchId,
    required this.taskId,
    required this.value,
    required this.measuredAt,
    this.measurementDefinitionId,
    this.metricName,
    this.extraData,
  });

  final String experimentId;
  final String? experimentStageId;
  final String? batchId;
  final String taskId;
  final double value;
  final DateTime measuredAt;
  final String? measurementDefinitionId;
  final String? metricName;
  final Map<String, dynamic>? extraData;
}

/// Build danh sách payload legacy.
List<SingleMeasurementPayload> buildMeasurementPayloads({
  required TaskGroupContext task,
  required List<LegacyMeasurementItem> measurements,
  required BridgeExtraMeta meta,
  required Map<String, MeasurementDefinitionModel> definitionLookup,
}) {
  if (measurements.isEmpty) return const [];
  final experimentId = task.experimentId;
  if (experimentId == null || experimentId.isEmpty) return const [];

  final measuredAt = meta.measuredAt ?? DateTime.now().toUtc();
  return measurements.map((m) {
    String? defId;
    // Theo FE JS: lookup theo name.
    final def = definitionLookup[m.name];
    defId = def?.id;

    return SingleMeasurementPayload(
      experimentId: experimentId,
      experimentStageId: task.experimentStageId,
      batchId: task.batchId,
      taskId: task.batchId ?? '', // analog task.id (BE yêu cầu)
      value: m.value,
      measuredAt: measuredAt,
      measurementDefinitionId: defId,
      metricName: defId == null ? m.name : null,
      extraData: meta.notes != null
          ? {'note': meta.notes, 'sourceKey': m.sourceKey}
          : null,
    );
  }).toList();
}

/// Build payload bulk.
class BulkMeasurementPayload {
  BulkMeasurementPayload({
    required this.experimentId,
    this.experimentStageId,
    required this.batchId,
    required this.measuredAt,
    this.extraData,
    required this.items,
  });

  final String experimentId;
  final String? experimentStageId;
  final String batchId;
  final DateTime measuredAt;
  final Map<String, dynamic>? extraData;
  final List<BulkItem> items;
}

BulkMeasurementPayload buildBulkMeasurementPayload({
  required TaskGroupContext task,
  required List<BulkItem> items,
  required BridgeExtraMeta meta,
}) {
  final measuredAt = meta.measuredAt ?? DateTime.now().toUtc();
  return BulkMeasurementPayload(
    experimentId: task.experimentId ?? '',
    experimentStageId: task.experimentStageId,
    batchId: task.batchId ?? '',
    measuredAt: measuredAt,
    extraData: meta.notes != null ? {'note': meta.notes} : null,
    items: items
        .where((i) => i.value.isFinite)
        .map((i) => BulkItem(
              definitionId: i.definitionId,
              value: i.value,
              metricName: i.metricName,
              unit: i.unit,
              targetValue: i.targetValue,
            ))
        .toList(),
  );
}

// ─── Bridge orchestrator (decision + builder pure) ──────────────────────────

/// Quyết định bulk/legacy path dựa trên taskType.
enum BridgePath { bulk, legacy, none }

BridgePath decideBridgePath(api.TaskType taskType) {
  if (isMeasurementTask(taskType)) return BridgePath.bulk;
  return BridgePath.legacy;
}

/// Pure bridge: build cả 2 loại payload từ `resultData`.
class BridgeOutput {
  const BridgeOutput({
    required this.path,
    this.bulk,
    this.singles = const [],
    this.skippedReasons = const [],
  });

  final BridgePath path;
  final BulkMeasurementPayload? bulk;
  final List<SingleMeasurementPayload> singles;
  final List<String> skippedReasons;

  bool get isEmpty => bulk == null && singles.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// Validate, filter và build payload. Không gọi API.
BridgeOutput buildBridgeOutput({
  required TaskGroupContext task,
  required Map<String, dynamic> resultData,
  required List<MeasurementDefinitionModel> effectiveDefinitions,
  required BridgeExtraMeta meta,
}) {
  debugPrint('[BRIDGE] buildBridgeOutput called');
  debugPrint('[BRIDGE] - resultData keys: ${resultData.keys.join(", ")}');
  debugPrint('[BRIDGE] - effectiveDefinitions count: ${effectiveDefinitions.length}');
  for (final d in effectiveDefinitions) {
    debugPrint('[BRIDGE]   def: ${d.id} (${d.metricName})');
  }
  
  final reasons = <String>[];

  if (task.experimentId == null || task.experimentId!.isEmpty) {
    debugPrint('[BRIDGE] FAIL: Missing experimentId');
    return BridgeOutput(
      path: BridgePath.none,
      skippedReasons: const ['Thiếu experimentId'],
    );
  }
  if (task.batchId == null || task.batchId!.isEmpty) {
    reasons.add('Thiếu batchId — MeasurementRecord sẽ không được tạo');
  }

  // Filter empty values.
  final filtered = <String, dynamic>{};
  resultData.forEach((k, v) {
    if (v == null) return;
    final s = v.toString().trim();
    if (s.isEmpty) return;
    filtered[k] = s;
  });

  debugPrint('[BRIDGE] Filtered resultData: ${filtered.keys.join(", ")}');

  if (filtered.isEmpty) {
    debugPrint('[BRIDGE] FAIL: filtered.isEmpty');
    return BridgeOutput(path: BridgePath.none);
  }

  final path = decideBridgePath(task.taskType ?? api.TaskType.other);
  debugPrint('[BRIDGE] Path decision: $path');

  if (path == BridgePath.bulk) {
    final items = extractBulkItemsFromResultData(filtered, effectiveDefinitions);
    debugPrint('[BRIDGE] Bulk items extracted: ${items.length}');
    for (final item in items) {
      debugPrint('[BRIDGE]   - ${item.definitionId} = ${item.value} (${item.metricName})');
    }
    if (items.isEmpty) {
      debugPrint('[BRIDGE] FAIL: No bulk items, falling back to legacy');
      return BridgeOutput(
        path: BridgePath.legacy,
        skippedReasons: ['Không có def_<uuid> nào — bulk path bị bỏ'],
      );
    }
    final bulk = buildBulkMeasurementPayload(
      task: task,
      items: items,
      meta: meta,
    );
    debugPrint('[BRIDGE] SUCCESS: Bulk payload built with ${bulk.items.length} items');
    return BridgeOutput(path: BridgePath.bulk, bulk: bulk, skippedReasons: reasons);
  }

  // Legacy path
  final measurements = extractMeasurementsFromReport(filtered);
  if (measurements.isEmpty) {
    return BridgeOutput(path: BridgePath.none, skippedReasons: reasons);
  }
  final byName = <String, MeasurementDefinitionModel>{};
  for (final d in effectiveDefinitions) {
    byName.putIfAbsent(d.metricName, () => d);
    byName.putIfAbsent(d.metricName.toLowerCase(), () => d);
  }
  final singles = buildMeasurementPayloads(
    task: task,
    measurements: measurements,
    meta: meta,
    definitionLookup: byName,
  );
  return BridgeOutput(path: BridgePath.legacy, singles: singles, skippedReasons: reasons);
}

// ─── Local validation ──────────────────────────────────────────────────────

/// Validation local cho 1 dynamic field. Trả `null` nếu OK.
/// Dùng minValue/maxValue nếu có, fallback sang legacy logic.
String? localValidateValue(
  MeasurementDefinitionModel? definition,
  String? raw,
) {
  if (raw == null || raw.trim().isEmpty) return null;
  final num = double.tryParse(raw.replaceAll(',', '.'));
  if (num == null) return 'Giá trị phải là số';
  if (num < 0) return 'Giá trị không được âm';

  final unit = (definition?.unit ?? '').trim();
  final name = (definition?.metricName ?? '').toLowerCase();
  final target = definition?.targetValue ?? double.nan;

  // Ưu tiên dùng minValue/maxValue nếu có
  final minVal = definition?.minValue;
  final maxVal = definition?.maxValue;
  if (minVal != null && num < minVal) {
    return '${definition?.metricName} phải >= $minVal';
  }
  if (maxVal != null && num > maxVal) {
    return '${definition?.metricName} phải <= $maxVal';
  }

  // Fallback legacy logic
  if (unit == '%' && num > 100) {
    return '${definition?.metricName} là phần trăm nên phải nằm trong [0, 100].';
  }
  if (name.contains('màu sắc') && (num < 1 || num > 5)) {
    return '${definition?.metricName} theo thang điểm 1–5.';
  }
  if (!target.isNaN && target > 0 && num > target * 5) {
    return '${definition?.metricName} vượt quá 5 lần target $target.';
  }
  return null;
}

/// Phân loại status: exceeded (đạt) / close / below.
enum ValueStatus { exceeded, close, below, ok, unknown }

ValueStatus getValueStatus(MeasurementDefinitionModel? definition, String? raw) {
  if (raw == null || raw.trim().isEmpty) return ValueStatus.unknown;
  final num = double.tryParse(raw.replaceAll(',', '.'));
  if (num == null) return ValueStatus.unknown;
  final target = definition?.targetValue ?? double.nan;
  if (target.isNaN) return ValueStatus.ok;
  if (num >= target) return ValueStatus.exceeded;
  if (num >= target * 0.8) return ValueStatus.close;
  return ValueStatus.below;
}

// ─── Custom field key generator ────────────────────────────────────────────

/// Sinh key `custom_N` không trùng với keys đã có.
String nextCustomKey(Set<String> existingKeys) {
  var n = 1;
  while (existingKeys.contains('custom_$n')) {
    n++;
  }
  return 'custom_$n';
}
