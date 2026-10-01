import 'dart:async';
import 'package:dio/dio.dart';
import 'rag_models.dart';

/// ─── RAG API Client ───────────────────────────────────────────────────────────
///
/// Maps 1-1 với RAG_Mobile_Integration.md sections 3.1 / 3.2.
///
/// Backend: https://rag-nong-nghiep-api-15ms.onrender.com
/// Auth: ❌ KHÔNG cần (public API, không có JWT).
///
/// Cold-start handling (mục 5):
///   - Render free plan sleep sau 15 phút → request đầu có thể mất 30-60s.
///   - Default timeout `/chat` = 60s (đủ wake server).
///   - Auto-retry 1 lần sau 5s nếu timeout (theo spec mục 5 "Best practices #4").
class RagApiClient {
  RagApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 60), // /chat cần 60s
              sendTimeout: const Duration(seconds: 30),
              headers: const {'Content-Type': 'application/json'},
              // KHÔNG auth header.
            ));

  static const String baseUrl = 'https://rag-nong-nghiep-api-15ms.onrender.com';

  final Dio _dio;

  /// GET /health — cache 30s (mục 3.1 implementation tip).
  Future<RagHealth> checkHealth() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final data = res.data ?? const {};
      return RagHealth.fromResponse(data);
    } catch (_) {
      return RagHealth.offline();
    }
  }

  /// POST /chat — endpoint chính.
  ///
  /// Spec mục 3.2:
  ///   - question: required
  ///   - history: chỉ gửi 12 messages gần nhất
  ///   - retrieval_only: default false (override theo setting user)
  ///   - knowledge_group: null = tất cả
  ///
  /// Retry 1 lần nếu timeout (cold start).
  Future<RagChatResult> chat({
    required String question,
    List<RagHistoryItem> history = const [],
    String? knowledgeGroup,
    bool retrievalOnly = false,
  }) async {
    final payload = <String, dynamic>{
      'question': question,
      'history': history.take(12).map((m) => m.toJson()).toList(),
      'retrieval_only': retrievalOnly,
      'knowledge_group': knowledgeGroup,
    };

    return _withRetry<RagChatResult>(() async {
      try {
        final res = await _dio.post<Map<String, dynamic>>(
          '$baseUrl/chat',
          data: payload,
        );
        final data = res.data ?? const {};
        return RagChatResult.fromJson(data);
      } on DioException catch (e) {
        // 422 validation: parse error message từ BE.
        if (e.response?.statusCode == 422) {
          return RagChatResult(
            success: false,
            answer: '',
            queryUsed: question,
            sources: const [],
            error: 'Validation error: ${e.response?.data}',
          );
        }
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          // timeout → propagate để retry wrapper xử lý.
          rethrow;
        }
        return RagChatResult(
          success: false,
          answer: '',
          queryUsed: question,
          sources: const [],
          error: 'HTTP ${e.response?.statusCode ?? "?"}: ${e.message}',
        );
      }
    });
  }

  /// Auto-retry 1 lần sau 5s nếu timeout (mục 5 best practice #4).
  Future<T> _withRetry<T>(Future<T> Function() fn, {int maxRetries = 1}) async {
    try {
      return await fn();
    } on DioException catch (e) {
      final isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout;
      if (isTimeout && maxRetries > 0) {
        await Future.delayed(const Duration(seconds: 5));
        return _withRetry(fn, maxRetries: maxRetries - 1);
      }
      rethrow;
    } on TimeoutException {
      if (maxRetries > 0) {
        await Future.delayed(const Duration(seconds: 5));
        return _withRetry(fn, maxRetries: maxRetries - 1);
      }
      rethrow;
    }
  }
}
