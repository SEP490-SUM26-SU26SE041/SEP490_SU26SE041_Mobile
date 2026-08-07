library;

import '../../utils/date_utils.dart';

enum BatchStatus { active, harvested, destroyed }

class BatchModel {
  const BatchModel({
    required this.id,
    required this.batchCode,
    required this.experimentId,
    required this.experimentGroupId,
    required this.experimentGroupName,
    required this.quantity,
    required this.plantingDate,
    required this.seedVariety,
    required this.status,
    this.source,
    this.notes,
  });

  final String id;
  final String batchCode;
  final String experimentId;
  final String experimentGroupId;
  final String experimentGroupName;
  final int quantity;
  final DateTime plantingDate;
  final String seedVariety;
  final BatchStatus status;
  final String? source;
  final String? notes;

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as String,
      batchCode: json['batchCode'] as String? ?? '',
      experimentId: json['experimentId'] as String? ?? '',
      experimentGroupId: json['experimentGroupId'] as String? ?? '',
      experimentGroupName: json['experimentGroupName'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      plantingDate: parseApiDateTimeOrNow(json['plantingDate']?.toString()),
      seedVariety: json['seedVariety'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      source: json['source'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'batchCode': batchCode,
    'experimentId': experimentId,
    'experimentGroupId': experimentGroupId,
    'experimentGroupName': experimentGroupName,
    'quantity': quantity,
    'plantingDate': plantingDate.toIso8601String(),
    'seedVariety': seedVariety,
    'status': status.name,
    if (source != null) 'source': source,
    if (notes != null) 'notes': notes,
  };
}

BatchStatus _parseStatus(String? s) {
  return switch (s?.toLowerCase()) {
    'active' => BatchStatus.active,
    'harvested' => BatchStatus.harvested,
    'destroyed' => BatchStatus.destroyed,
    _ => BatchStatus.active,
  };
}
