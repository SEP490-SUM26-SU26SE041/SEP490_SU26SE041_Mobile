library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';
import '../api_endpoints.dart';
import '../models/dashboard_model.dart';

final dashboardApiServiceProvider = Provider<DashboardApiService>((ref) {
  return DashboardApiService(ref.read(dioProvider));
});

class DashboardApiService {
  DashboardApiService(this._dio);
  final Dio _dio;

  /// GET /dashboard/overview
  /// Optional filter by farmId / experimentId for role-based context.
  Future<DashboardOverviewModel> overview({
    String? farmId,
    String? experimentId,
  }) async {
    final params = <String, dynamic>{};
    if (farmId != null) params['farmId'] = farmId;
    if (experimentId != null) params['experimentId'] = experimentId;

    final res = await _dio.get(ApiEndpoints.dashboardOverview,
        queryParameters: params.isEmpty ? null : params);
    final data = res.data;
    return DashboardOverviewModel.fromJson(
        data is Map<String, dynamic> ? data : <String, dynamic>{});
  }

  /// GET /dashboard/kpis
  Future<List<DashboardKpiModel>> kpis({
    String? farmId,
    String? experimentId,
  }) async {
    final params = <String, dynamic>{};
    if (farmId != null) params['farmId'] = farmId;
    if (experimentId != null) params['experimentId'] = experimentId;
    final res = await _dio.get(ApiEndpoints.dashboardKpis,
        queryParameters: params.isEmpty ? null : params);
    final data = res.data;
    List<dynamic> list = const [];
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) list = inner;
    }
    return list
        .whereType<Map>()
        .map((e) =>
            DashboardKpiModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /dashboard/alerts
  Future<List<DashboardAlertModel>> alerts({
    String? farmId,
    String? experimentId,
  }) async {
    final params = <String, dynamic>{};
    if (farmId != null) params['farmId'] = farmId;
    if (experimentId != null) params['experimentId'] = experimentId;
    final res = await _dio.get(ApiEndpoints.dashboardAlerts,
        queryParameters: params.isEmpty ? null : params);
    final data = res.data;
    List<dynamic> list = const [];
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) list = inner;
    }
    return list
        .whereType<Map>()
        .map((e) =>
            DashboardAlertModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /dashboard/personnel/performance
  /// Trả về performance metrics cho user hiện tại (technician/student).
  Future<Map<String, dynamic>> personnelPerformance({String? userId}) async {
    final url = userId != null
        ? '/dashboard/personnel/$userId/performance'
        : ApiEndpoints.dashboardPersonnelPerformance;
    final res = await _dio.get(url);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    return <String, dynamic>{};
  }
}
