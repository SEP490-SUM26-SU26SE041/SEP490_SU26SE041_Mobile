import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/services/experiment_api_service.dart';

/// Thông tin metric dùng để map metricName + unit cho 1 measurement definition.
class MeasurementDefinitionInfo {
  const MeasurementDefinitionInfo({
    required this.id,
    required this.metricName,
    this.unit,
  });
  final String id;
  final String metricName;
  final String? unit;
}

/// Cache: `experimentId` → Map<definitionId, MeasurementDefinitionInfo>.
///
/// Gọi `GET /experiments/{id}/measurements` 1 lần cho mỗi experiment → cache
/// trong session để tra cứu nhanh khi render lịch sử báo cáo / nhật ký tăng trưởng.
final measurementDefinitionsByExperimentProvider =
    FutureProvider.autoDispose
        .family<Map<String, MeasurementDefinitionInfo>, String>(
  (ref, experimentId) async {
    if (experimentId.isEmpty) return const {};
    final api = ref.read(experimentApiServiceProvider);
    final raw = await api.getMeasurementDefinitions(experimentId);
    final map = <String, MeasurementDefinitionInfo>{};
    for (final json in raw) {
      final id = (json['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final name = (json['metricName'] ?? json['name'] ?? 'Chỉ số').toString();
      final unit = json['unit']?.toString();
      map[id] = MeasurementDefinitionInfo(id: id, metricName: name, unit: unit);
    }
    return map;
  },
);

/// Helper: lấy `name` cho 1 definitionId trong 1 experiment (sync nếu đã cache).
/// Trả về `null` nếu chưa load xong hoặc ID không tồn tại.
String? resolveMetricName(
  Map<String, MeasurementDefinitionInfo>? map,
  String definitionId,
) {
  if (map == null) return null;
  final info = map[definitionId];
  if (info == null) return null;
  return info.metricName;
}

/// Helper: lấy `unit` cho 1 definitionId.
String? resolveMetricUnit(
  Map<String, MeasurementDefinitionInfo>? map,
  String definitionId,
) {
  if (map == null) return null;
  final info = map[definitionId];
  if (info == null) return null;
  return info.unit;
}
