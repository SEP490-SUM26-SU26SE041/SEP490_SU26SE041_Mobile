library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Base URL:
/// - Android emulator → 10.0.2.2 (localhost của máy host)
/// - iOS simulator   → localhost hoặc 10.0.2.2
/// - Web/Production  → IP/domain thật
const _baseUrl = 'https://smartfarm-sep490-api-c3emdvfmdefybacs.eastasia-01.azurewebsites.net/api';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(_dioOptions);

  // Dev: bypass SSL để hỗ trợ self-signed cert trên localhost
  dio.httpClientAdapter = _createDevAdapter();

  dio.interceptors.addAll([
    AuthInterceptor(),
    ErrorInterceptor(),
    if (kDebugMode)
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('[API] $o'),
      ),
  ]);

  return dio;
});

BaseOptions get _dioOptions => BaseOptions(
  baseUrl: _baseUrl,
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  sendTimeout: const Duration(seconds: 30),
  validateStatus: (status) => true,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
);

/// Tạo adapter với SSL bypass cho dev.
HttpClientAdapter _createDevAdapter() {
  final adapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      // Bypass SSL verification cho self-signed cert trên localhost
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    },
  );
  return adapter;
}

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    const storage = FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // ignore storage errors — proceed without token
    }
    handler.next(options);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isConnectionError = switch (err.type) {
      DioExceptionType.connectionTimeout => true,
      DioExceptionType.sendTimeout => true,
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.connectionError => true,
      DioExceptionType.unknown => true,
      _ => false,
    };

    String message;
    if (isConnectionError) {
      message =
          'Không thể kết nối máy chủ. Kiểm tra mạng và đảm bảo backend đang chạy.';
    } else {
      final statusCode = err.response?.statusCode;
      switch (statusCode) {
        case 400:
          message = _parseErrorMessage(err.response) ?? 'Yêu cầu không hợp lệ';
        case 401:
          message = 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
        case 403:
          message = 'Bạn không có quyền thực hiện thao tác này.';
        case 404:
          message =
              _parseErrorMessage(err.response) ?? 'Không tìm thấy dữ liệu';
        case 500:
          message = 'Lỗi máy chủ. Vui lòng thử lại sau.';
        default:
          message = _parseErrorMessage(err.response) ??
              'Đã xảy ra lỗi. Vui lòng thử lại.';
      }
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ApiException(
          statusCode: err.response?.statusCode,
          message: message,
        ),
      ),
    );
  }

  String? _parseErrorMessage(Response? response) {
    if (response == null) return null;
    final data = response.data;
    if (data is Map) {
      return data['message'] ?? data['error'] ?? data['title'];
    }
    return null;
  }
}

class ApiException implements Exception {
  const ApiException({this.statusCode, required this.message});
  final int? statusCode;
  final String message;

  @override
  String toString() => message;
}
