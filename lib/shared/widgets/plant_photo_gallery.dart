import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/api/models/dashboard_model.dart';

class PlantPhotoGallery extends StatelessWidget {
  const PlantPhotoGallery({
    super.key,
    this.images = const [],
    this.maxPhotos = 6,
    this.showSectionTitle = true,
    this.onImageTap,
  });

  final List<TaskImageItem> images;
  final int maxPhotos;
  final bool showSectionTitle;
  final void Function(TaskImageItem image)? onImageTap;

  @override
  Widget build(BuildContext context) {
    final displayImages = images.take(maxPhotos).toList();

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
                Text('Hình ảnh cây gần đây',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (images.length > maxPhotos) ...[
                  const Spacer(),
                  Text(
                    '+${images.length - maxPhotos}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
        if (displayImages.isEmpty)
          _buildEmptyState(context)
        else
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) => _PhotoCard(
                image: displayImages[index],
                onTap: onImageTap != null ? () => onImageTap!(displayImages[index]) : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(40),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Chưa có hình ảnh cây gần đây',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.image,
    this.onTap,
  });

  final TaskImageItem image;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: image.caption ?? 'Hình ảnh cây từ ${image.batchCode ?? 'batch'}',
        button: onTap != null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 130,
                height: 130,
                child: image.imageUrl.isNotEmpty
                    ? Image.network(
                        image.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(context),
                        loadingBuilder: (_, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildLoadingPlaceholder(context, loadingProgress);
                        },
                      )
                    : _buildErrorPlaceholder(context),
              ),
            ),
            if (image.caption != null && image.caption!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: 130,
                child: Text(
                  image.caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withAlpha(153),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(77),
        size: 40,
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context, ImageChunkEvent loadingProgress) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }
}
