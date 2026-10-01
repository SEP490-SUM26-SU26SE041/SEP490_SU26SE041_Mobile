// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../providers/task_providers.dart';

/// Bottom sheet hiển thị chi tiết báo cáo + ảnh minh chứng cho 1 task.
///
/// Được dùng từ nhiều nơi:
/// - Nút "Xem báo cáo" trong task detail (premium task card)
/// - Bấm ảnh trong `PlantPhotoGallery` của dashboard (cả student & technician)
/// - Các màn hình khác cần xem report nhanh không cần điều hướng
class TaskReportDetailSheet extends ConsumerWidget {
  const TaskReportDetailSheet({
    super.key,
    required this.taskId,
    required this.taskName,
  });

  final String taskId;
  final String taskName;

  /// Helper mở bottom sheet — dùng `showModalBottomSheet` cho giống UX
  /// "Xem báo cáo" của task detail.
  static Future<void> show(
    BuildContext context, {
    required String taskId,
    required String taskName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskReportDetailSheet(
        taskId: taskId,
        taskName: taskName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reportAsync = ref.watch(taskReportByTaskProvider(taskId));
    final imagesAsync = ref.watch(taskImagesByTaskProvider(taskId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                      .withAlpha(128),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assessment_rounded,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Báo cáo: $taskName',
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Thông tin báo cáo từ người thực hiện',
                      style: tt.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          const Divider(height: 1),

          Flexible(
            child: reportAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 64,
                          color: (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight)
                              .withAlpha(77),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có báo cáo',
                          style: tt.titleMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Báo cáo sẽ được cập nhật sau khi công việc hoàn thành',
                          style: tt.bodySmall?.copyWith(
                            color: (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight)
                                .withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final sorted = [...reports]
                  ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
                final report = sorted.first;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReportDetailItem(
                        icon: Icons.description_rounded,
                        label: 'Nội dung báo cáo',
                        value: report.description.isNotEmpty
                            ? report.description
                            : report.title,
                        color: AppColors.info,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _ReportDetailItem(
                        icon: Icons.person_rounded,
                        label: 'Người nộp',
                        value: report.submittedBy ?? 'Không xác định',
                        color: AppColors.primary,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _ReportDetailItem(
                        icon: Icons.calendar_today_rounded,
                        label: 'Ngày nộp',
                        value: _formatDateTime(report.submittedAt),
                        color: AppColors.success,
                        isDark: isDark,
                      ),

                      // Task Images
                      const SizedBox(height: 24),
                      Row(children: [
                        Icon(Icons.photo_library_rounded,
                            size: 20, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text('Hình ảnh',
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 12),
                      imagesAsync.when(
                        data: (images) {
                          if (images.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.backgroundDark
                                        : AppColors.backgroundLight)
                                    .withAlpha(128),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Chưa có hình ảnh',
                                  style: tt.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ),
                            );
                          }
                          return SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                final image = images[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                      right: index < images.length - 1 ? 12 : 0),
                                  child: GestureDetector(
                                    onTap: () =>
                                        _showImageFullScreen(context, image.imageUrl),
                                    child: Container(
                                      width: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: AppColors.primary.withAlpha(20),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          image.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const Center(
                                                  child: Icon(
                                                      Icons.broken_image_rounded)),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Lỗi tải ảnh: $e'),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageFullScreen(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) => formatDateTime(dt);
}

class _ReportDetailItem extends StatelessWidget {
  const _ReportDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: tt.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                Text(value,
                    style: tt.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}