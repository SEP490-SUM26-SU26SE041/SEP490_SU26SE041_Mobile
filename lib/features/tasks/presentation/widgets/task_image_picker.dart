import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Widget chọn ảnh từ camera/gallery + preview thumbnails.
/// Gọi [onUpload] sau khi user chọn ảnh (để parent upload lên server).
///
/// [images] — danh sách ảnh local đã chọn (File).
/// [onImagesChanged] — callback khi user thêm/xóa ảnh.
/// [isUploading] — disable các nút khi đang upload.
class TaskImagePicker extends StatelessWidget {
  const TaskImagePicker({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.isUploading = false,
  });

  final List<File> images;
  final void Function(List<File>) onImagesChanged;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + Add button
        Row(
          children: [
            Icon(Icons.photo_library_outlined,
                size: 16, color: Theme.of(context).colorScheme.onSurface.withAlpha(153)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Ảnh minh chứng',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Text(
              '${images.length}/5 ảnh',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Thumbnail row
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Nút thêm ảnh (max 5)
              if (images.length < 5) _AddImageButton(onPressed: () => _showSourceSheet(context)),
              // Ảnh đã chọn
              ...images.asMap().entries.map((e) => _ImageThumbnail(
                    file: e.value,
                    onRemove: isUploading ? null : () {
                      final updated = List<File>.from(images)..removeAt(e.key);
                      onImagesChanged(updated);
                    },
                  )),
            ],
          ),
        ),

        if (images.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ảnh sẽ được gửi kèm báo cáo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.info,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ],
    );
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(
        onCamera: () {
          Navigator.pop(context);
          _pickImage(context, ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(context, ImageSource.gallery);
        },
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (picked != null) {
        final updated = List<File>.from(images)..add(File(picked.path));
        onImagesChanged(updated);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
        );
      }
    }
  }
}

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: cs.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.withAlpha(80), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 28, color: cs.onSurface.withAlpha(100)),
                const SizedBox(height: 4),
                Text(
                  'Thêm ảnh',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withAlpha(100),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.file, required this.onRemove});

  final File file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, url, error) => Container(
                width: 80,
                height: 80,
                color: AppColors.surfaceLight,
                child: const Icon(Icons.broken_image_rounded, color: Colors.white),
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Chọn nguồn ảnh',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _SourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Chụp ảnh',
                    subtitle: 'Chụp ảnh minh chứng',
                    onTap: onCamera,
                  ),
                  const SizedBox(height: 12),
                  _SourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Chọn từ thư viện',
                    subtitle: 'Chọn ảnh đã lưu',
                    onTap: onGallery,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon, required this.label,
    required this.subtitle, required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withAlpha(120),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurface.withAlpha(120)),
            ],
          ),
        ),
      ),
    );
  }
}
