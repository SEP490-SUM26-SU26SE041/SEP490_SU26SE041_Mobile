import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/task_report_model.dart';
import '../../../../core/constants/ai_providers.dart';
import '../../../../core/constants/tomato_disease_map.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../tasks/providers/task_image_providers.dart';

/// Modal hiển thị kết quả AI scan + retry + polling tự động.
///
/// Polling logic:
///   - Mỗi 5s gọi GET /task-images/task/{reportId}/detail?includeAnalysis=true
///   - Tìm image có id khớp → cập nhật local state
///   - Khi aiStatus = Completed/Failed → stop polling
///   - Timeout 2 phút → stop + show error
class AiResultModal extends ConsumerStatefulWidget {
  const AiResultModal({
    super.key,
    required this.initialImage,
    required this.taskReportId,
    this.onImageUpdated,
    this.onRetry,
  });

  /// TaskImage ban đầu (đã có id + aiStatus).
  final TaskImageModel initialImage;

  /// Report id — cần thiết cho polling endpoint.
  final String taskReportId;

  /// Callback khi ảnh được cập nhật (qua polling hoặc retry).
  final void Function(TaskImageModel)? onImageUpdated;

  /// Callback khi user bấm Retry (parent gọi API, modal tự polling).
  final Future<void> Function(String imageId)? onRetry;

  @override
  ConsumerState<AiResultModal> createState() => _AiResultModalState();
}

class _AiResultModalState extends ConsumerState<AiResultModal> {
  late TaskImageModel _image;
  Timer? _pollTimer;
  Timer? _elapsedTimer;
  bool _isRetrying = false;
  bool _pollError = false;
  int _elapsedSec = 0;
  static const _pollMs = 5000;
  static const _timeoutMs = 120000; // 2 phút
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
    _maybeStartPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  void _maybeStartPolling() {
    if (_image.isAiPending) {
      _startPolling();
    }
  }

  void _startPolling() {
    if (!mounted) return;
    if (widget.taskReportId.isEmpty) {
      debugPrint('[AiResultModal] startPolling: thiếu taskReportId prop');
      return;
    }
    _stopPolling();
    _startedAt = DateTime.now();
    setState(() {
      _pollError = false;
      _elapsedSec = 0;
    });
    // Tick ngay + interval
    _tick();
    _pollTimer = Timer.periodic(const Duration(milliseconds: _pollMs), (_) => _tick());
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSec++);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  Future<void> _tick() async {
    if (!mounted) return;
    final id = _image.id;
    try {
      final list = await ref.read(
        taskImagesByReportWithAnalysisProvider(widget.taskReportId).future,
      );
      final updated = list.where((img) => img.id == id).cast<TaskImageModel?>().firstWhere(
            (_) => true,
            orElse: () => null,
          );
      if (updated == null) return;
      if (!mounted) return;
      setState(() => _image = updated);
      if (updated.isAiDone) {
        _stopPolling();
        widget.onImageUpdated?.call(updated);
      }
    } catch (err) {
      if (!mounted) return;
      setState(() => _pollError = true);
      debugPrint('[AiResultModal] poll error: $err');
    }
    // Timeout check
    final started = _startedAt;
    if (started != null && DateTime.now().difference(started).inMilliseconds > _timeoutMs) {
      _stopPolling();
      if (!mounted) return;
      setState(() => _pollError = true);
    }
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    final id = _image.id;
    setState(() {
      _isRetrying = true;
      _pollError = false;
    });
    try {
      if (widget.onRetry != null) {
        await widget.onRetry!(id);
      } else {
        await ref.read(retryAiScanProvider(id).future);
      }
      // Sau retry → bắt đầu polling lại
      _startPolling();
    } catch (err) {
      debugPrint('[AiResultModal] retry error: $err');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Retry thất bại: $err')),
      );
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isPending = _image.isAiPending;
    final isFailed = _image.isAiFailed;
    final isCompleted = _image.isAiCompleted;
    final progress = (_elapsedSec * 1000 / _timeoutMs).clamp(0.0, 1.0);

    return Dialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(tt, cs),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _imagePreview(cs),
                    const SizedBox(height: AppSpacing.md),
                    _statusChip(tt, cs),
                    if (isPending) ...[
                      const SizedBox(height: AppSpacing.md),
                      _pollingIndicator(tt, cs, progress),
                    ],
                    if (isFailed) ...[
                      const SizedBox(height: AppSpacing.md),
                      _errorBox(tt, cs),
                    ],
                    if (isCompleted) ...[
                      const SizedBox(height: AppSpacing.md),
                      _analysisSection(tt, cs),
                    ],
                    if (_pollError && !isFailed && !isCompleted) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Lỗi khi poll — sẽ thử lại sau 5s',
                        style: tt.bodySmall?.copyWith(color: AppColors.warning),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ),
                  if (isFailed || (isCompleted && _image.aiAnalysis?.hasError == true)) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isRetrying ? null : _handleRetry,
                        icon: _isRetrying
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(_isRetrying ? 'Đang retry...' : 'Retry AI Scan'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(TextTheme tt, ColorScheme cs) {
    final meta = AiProviders.getMeta(_image.aiProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(meta.colorValue).withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(meta.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(meta.shortName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(meta.colorValue),
                      fontSize: 11,
                    )),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Kết quả AI Scan',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _imagePreview(ColorScheme cs) {
    final annotatedUrl = _image.aiAnnotatedImageUrl ??
        _image.aiAnalysis?.annotatedImageUrl;
    final previewUrl = annotatedUrl ?? _image.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 280),
        width: double.infinity,
        color: cs.surfaceContainerHighest,
        child: previewUrl.isEmpty
            ? const Center(child: Icon(Icons.image_not_supported_outlined))
            : Image.network(
                previewUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                errorBuilder: (_, _, _) => Image.network(
                  _image.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image_rounded, size: 48),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _statusChip(TextTheme tt, ColorScheme cs) {
    String label;
    Color color;
    IconData icon;
    if (_image.isAiPending) {
      label = 'Đang xử lý...';
      color = AppColors.info;
      icon = Icons.hourglass_top_rounded;
    } else if (_image.isAiFailed) {
      label = 'AI scan thất bại';
      color = AppColors.error;
      icon = Icons.error_outline_rounded;
    } else if (_image.isAiCompleted) {
      final analysis = _image.aiAnalysis;
      if (analysis?.hasError == true) {
        label = 'Hoàn thành (có lỗi)';
        color = AppColors.warning;
        icon = Icons.warning_amber_rounded;
      } else if (analysis?.isGateRejection == true) {
        label = 'Hoàn thành · ${TomatoDiseaseMap.vietnamese(analysis?.finalStatus)}';
        color = AppColors.warning;
        icon = Icons.check_circle_outline;
      } else {
        label = 'Hoàn thành';
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
      }
    } else {
      label = 'Chưa scan';
      color = cs.onSurface.withAlpha(120);
      icon = Icons.smart_toy_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: tt.bodyMedium?.copyWith(color: color))),
        ],
      ),
    );
  }

  Widget _pollingIndicator(TextTheme tt, ColorScheme cs, double progress) {
    final elapsed = _elapsedSec;
    final totalSec = _timeoutMs ~/ 1000;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text('Đang chờ AI xử lý... ($elapsed s / $totalSec s)',
                  style: tt.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.info.withAlpha(30),
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 8),
          Text('Tự động reload kết quả mỗi 5 giây. Bạn có thể đóng modal và quay lại sau.',
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(150))),
        ],
      ),
    );
  }

  Widget _errorBox(TextTheme tt, ColorScheme cs) {
    final msg = _image.aiAnalysis?.errorMessage ??
        _image.aiAnalysis?.finalStatus ??
        'Lỗi không xác định';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 18),
              const SizedBox(width: 6),
              Text('Lỗi scan', style: tt.titleSmall?.copyWith(color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 6),
          Text(msg, style: tt.bodySmall),
        ],
      ),
    );
  }

  Widget _analysisSection(TextTheme tt, ColorScheme cs) {
    final a = _image.aiAnalysis;
    if (a == null) return const SizedBox.shrink();

    if (a.isGateRejection) {
      return _gateRejection(tt, cs, a);
    }
    return _normalResult(tt, cs, a);
  }

  Widget _gateRejection(TextTheme tt, ColorScheme cs, AiAnalysisModel a) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: 6),
              Text(
                TomatoDiseaseMap.vietnamese(a.finalStatus),
                style: tt.titleSmall?.copyWith(color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ảnh không phải lá cà chua — model gate đã reject trước khi phân loại bệnh.',
            style: tt.bodySmall,
          ),
          if (a.gateLabel != null) ...[
            const SizedBox(height: 8),
            _kv(tt, 'Gate label', a.gateLabel!),
          ],
          if (a.gateConfidence != null)
            _kv(tt, 'Gate confidence', (a.gateConfidence! * 100).toStringAsFixed(1) + '%'),
        ],
      ),
    );
  }

  Widget _normalResult(TextTheme tt, ColorScheme cs, AiAnalysisModel a) {
    final label = a.label ?? _image.aiPredictedLabel;
    final conf = a.confidence ?? _image.aiConfidence;
    final labelVn = label != null
        ? TomatoDiseaseMap.vietnamese(label)
        : 'Không có nhãn';
    final severity = label != null
        ? TomatoDiseaseMap.severity(label)
        : DiseaseSeverity.none;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv(tt, 'Kết quả', labelVn),
          if (conf != null)
            _kv(tt, 'Độ tin cậy', (conf * 100).toStringAsFixed(1) + '%'),
          _kv(tt, 'Severity', severity.label),
          if (a.detectionCount != null)
            _kv(tt, 'Số detection', a.detectionCount.toString()),
          if (a.apiVersion != null)
            _kv(tt, 'API version', a.apiVersion!),
          if (a.gateLabel != null)
            _kv(tt, 'Gate label', a.gateLabel!),
          if (a.gateConfidence != null)
            _kv(tt, 'Gate confidence', (a.gateConfidence! * 100).toStringAsFixed(1) + '%'),
        ],
      ),
    );
  }

  Widget _kv(TextTheme tt, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(k,
                style: tt.bodySmall
                    ?.copyWith(color: tt.bodySmall?.color?.withAlpha(180))),
          ),
          Expanded(
            child: Text(v,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Helper mở modal dễ dàng.
Future<void> showAiResultModal(
  BuildContext context, {
  required TaskImageModel image,
  required String taskReportId,
  void Function(TaskImageModel)? onImageUpdated,
  Future<void> Function(String imageId)? onRetry,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withAlpha(120),
    builder: (_) => AiResultModal(
      initialImage: image,
      taskReportId: taskReportId,
      onImageUpdated: onImageUpdated,
      onRetry: onRetry,
    ),
  );
}
