import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../mock/mock_plant_photos.dart';
import '../../shared/models/care_activity_model.dart';

class PlantPhotoGallery extends StatelessWidget {
  const PlantPhotoGallery({super.key, this.maxPhotos = 6, this.showSectionTitle = true});

  final int maxPhotos;
  final bool showSectionTitle;

  @override
  Widget build(BuildContext context) {
    final photos = mockPlantPhotos.take(maxPhotos).toList();
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSectionTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1F4D3D), Color(0xFF3D7A5D)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Hình ảnh cây gần đây',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${photos.length}',
                    style: tt.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _PlantPhotoCard(photo: photo, tt: tt);
            },
          ),
        ),
      ],
    );
  }
}

class _PlantPhotoCard extends StatelessWidget {
  const _PlantPhotoCard({required this.photo, required this.tt});

  final PlantPhotoModel photo;
  final TextTheme tt;

  Color get _typeColor => switch (photo.imageType) {
    PlantImageType.growth => AppColors.success,
    PlantImageType.pest => AppColors.error,
    PlantImageType.disease => AppColors.warning,
    PlantImageType.environment => AppColors.info,
    PlantImageType.general => AppColors.primary,
    _ => AppColors.primary,
  };

  IconData get _typeIcon => switch (photo.imageType) {
    PlantImageType.growth => Icons.trending_up_rounded,
    PlantImageType.pest => Icons.bug_report_rounded,
    PlantImageType.disease => Icons.warning_rounded,
    PlantImageType.environment => Icons.landscape_rounded,
    PlantImageType.general => Icons.eco_rounded,
    _ => Icons.image_rounded,
  };

  String get _typeLabel => switch (photo.imageType) {
    PlantImageType.growth => 'Tăng trưởng',
    PlantImageType.pest => 'Sâu bệnh',
    PlantImageType.disease => 'Bệnh cây',
    PlantImageType.environment => 'Môi trường',
    PlantImageType.general => 'Tổng quan',
    _ => 'Khác',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return GestureDetector(
      onTap: () => _showPhotoDetail(context),
      child: Container(
        width: 145,
        decoration: BoxDecoration(
          color: bgSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor.withAlpha(100), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 22 : 10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _typeColor.withAlpha(35),
                          _typeColor.withAlpha(15),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(_typeIcon, color: _typeColor.withAlpha(160), size: 42),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: bgSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _typeColor.withAlpha(60), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_typeIcon, size: 9, color: _typeColor),
                          const SizedBox(width: 3),
                          Text(
                            _typeLabel,
                            style: TextStyle(
                              color: _typeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: borderColor.withAlpha(60), width: 0.8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.batchName,
                    style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 9, color: _typeColor.withAlpha(180)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _formatTime(photo.uploadedAt),
                          style: tt.labelSmall?.copyWith(
                            color: _typeColor.withAlpha(180),
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PhotoDetailSheet(photo: photo),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    if (diff.inDays < 7) return '${diff.inDays}d trước';
    return DateFormat('dd/MM').format(dt);
  }
}

class _PhotoDetailSheet extends StatelessWidget {
  const _PhotoDetailSheet({required this.photo});

  final PlantPhotoModel photo;

  Color get _typeColor => switch (photo.imageType) {
    PlantImageType.growth => AppColors.success,
    PlantImageType.pest => AppColors.error,
    PlantImageType.disease => AppColors.warning,
    PlantImageType.environment => AppColors.info,
    PlantImageType.general => AppColors.primary,
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _typeColor.withAlpha(40),
                  _typeColor.withAlpha(20),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(Icons.eco_rounded, color: _typeColor.withAlpha(180), size: 64),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(photo.batchName, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                if (photo.caption != null) ...[
                  const SizedBox(height: 8),
                  Text(photo.caption!, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153))),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: cs.onSurface.withAlpha(128)),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd/MM/yyyy HH:mm').format(photo.uploadedAt),
                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
