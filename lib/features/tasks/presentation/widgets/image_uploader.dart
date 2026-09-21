import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/ai_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Một ảnh local + AI provider riêng + preview.
class UploadImageItem {
  UploadImageItem({
    required this.file,
    required this.previewUrl,
    this.caption = '',
    this.aiProvider,
    this.localId,
  });

  final File file;
  final String previewUrl;
  String caption;
  String? aiProvider;
  final String? localId;
}

/// Widget upload ảnh với **mỗi ảnh 1 AI provider riêng** (v5).
///
/// Tính năng:
///   - Bấm vào tile ảnh → mở picker dưới tile (không bay ra ngoài)
///   - Bấm provider trong picker → cập nhật ngay, đóng picker
///   - Bấm ảnh khác → picker ảnh cũ đóng, picker ảnh mới mở
///   - Single-select picker, click-anywhere
class ImageUploader extends StatefulWidget {
  const ImageUploader({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.maxFiles = 5,
    this.maxSizeMb = 10,
    this.disabled = false,
    this.defaultAiProvider = AiProviders.defaultProvider,
    this.enableAiScan = true,
  });

  /// Danh sách ảnh hiện tại.
  final List<UploadImageItem> images;

  /// Callback khi user thêm/xóa/đổi provider.
  final void Function(List<UploadImageItem>) onImagesChanged;

  /// Giới hạn số ảnh tối đa.
  final int maxFiles;

  /// Giới hạn dung lượng mỗi ảnh (MB).
  final int maxSizeMb;

  /// Disable toàn bộ (khi đang upload).
  final bool disabled;

  /// Provider mặc định cho ảnh mới.
  final String defaultAiProvider;

  /// Có cho phép AI scan không. False → ảnh mới có aiProvider=null.
  final bool enableAiScan;

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  int? _pickerFor; // index của ảnh đang mở picker (null = không mở)

  @override
  void dispose() {
    for (final item in widget.images) {
      // Revoke preview URLs để tránh leak.
      try {
        // ignore: deprecated_member_use
        Uri.parse(item.previewUrl); // dummy
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _addImages(ImageSource source) async {
    if (widget.disabled) return;
    final picker = ImagePicker();
    try {
      if (source == ImageSource.camera) {
        final XFile? picked = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 80,
        );
        if (picked != null) _appendFile(File(picked.path));
      } else {
        final List<XFile> picked = await picker.pickMultiImage(
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 80,
        );
        for (final x in picked) {
          _appendFile(File(x.path));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
      );
    }
  }

  void _appendFile(File file) {
    final remaining = widget.maxFiles - widget.images.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đạt giới hạn ${widget.maxFiles} ảnh')),
      );
      return;
    }
    final sizeMb = file.lengthSync() / (1024 * 1024);
    if (sizeMb > widget.maxSizeMb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ảnh quá ${widget.maxSizeMb}MB (${sizeMb.toStringAsFixed(1)}MB)')),
      );
      return;
    }
    final item = UploadImageItem(
      file: file,
      previewUrl: '', // dùng Image.file thay vì network URL
      aiProvider: widget.enableAiScan ? widget.defaultAiProvider : null,
      localId: 'local_${DateTime.now().millisecondsSinceEpoch}',
    );
    widget.onImagesChanged([...widget.images, item]);
  }

  void _removeAt(int idx) {
    final updated = List<UploadImageItem>.from(widget.images)..removeAt(idx);
    widget.onImagesChanged(updated);
    if (_pickerFor == idx) {
      setState(() => _pickerFor = null);
    } else if (_pickerFor != null && _pickerFor! > idx) {
      setState(() => _pickerFor = _pickerFor! - 1);
    }
  }

  void _togglePicker(int idx) {
    if (widget.disabled) return;
    setState(() {
      _pickerFor = _pickerFor == idx ? null : idx;
    });
  }

  void _changeProvider(int idx, String? newProvider) {
    final updated = List<UploadImageItem>.from(widget.images);
    updated[idx] = UploadImageItem(
      file: updated[idx].file,
      previewUrl: updated[idx].previewUrl,
      caption: updated[idx].caption,
      aiProvider: newProvider,
      localId: updated[idx].localId,
    );
    widget.onImagesChanged(updated);
    setState(() => _pickerFor = null);
  }

  void _changeCaption(int idx, String caption) {
    final updated = List<UploadImageItem>.from(widget.images);
    updated[idx] = UploadImageItem(
      file: updated[idx].file,
      previewUrl: updated[idx].previewUrl,
      caption: caption,
      aiProvider: updated[idx].aiProvider,
      localId: updated[idx].localId,
    );
    widget.onImagesChanged(updated);
  }

  void _showSourceSheet() {
    if (widget.disabled) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SourceSheet(
        onCamera: () {
          Navigator.pop(context);
          _addImages(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _addImages(ImageSource.gallery);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasImages = widget.images.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.photo_library_outlined,
                size: 16, color: cs.onSurface.withAlpha(153)),
            const SizedBox(width: AppSpacing.sm),
            Text('Ảnh minh chứng',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${widget.images.length}/${widget.maxFiles}',
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(128)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!hasImages)
          _EmptyState(onTap: _showSourceSheet)
        else
          Column(
            children: [
              // Image tiles grid
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (int i = 0; i < widget.images.length; i++)
                    _ImageTile(
                      item: widget.images[i],
                      isPicking: _pickerFor == i,
                      onTapImage: () => _togglePicker(i),
                      onRemove: widget.disabled
                          ? null
                          : () => _removeAt(i),
                    ),
                  if (widget.images.length < widget.maxFiles)
                    _AddTile(
                      onTap: widget.disabled ? null : _showSourceSheet,
                    ),
                ],
              ),
              // Picker (in-place, ngay dưới grid)
              if (_pickerFor != null)
                _ProviderPicker(
                  currentProvider: widget.images[_pickerFor!].aiProvider,
                  enableAiScan: widget.enableAiScan,
                  onSelect: (p) => _changeProvider(_pickerFor!, p),
                ),
              // Caption fields (one per image)
              if (widget.images.length <= 3)
                ...widget.images.asMap().entries.map(
                      (e) => _CaptionField(
                        caption: e.value.caption,
                        onChanged: (v) => _changeCaption(e.key, v),
                        disabled: widget.disabled,
                      ),
                    )
              else
                _CaptionField(
                  caption: widget.images.first.caption,
                  onChanged: (v) => _changeCaption(0, v),
                  disabled: widget.disabled,
                  hint: 'Mô tả cho tất cả ảnh...',
                ),
            ],
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Material(
      color: cs.surfaceContainerHighest.withAlpha(60),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withAlpha(60), style: BorderStyle.solid),
          ),
          child: Column(
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 36, color: cs.onSurface.withAlpha(120)),
              const SizedBox(height: 6),
              Text('Chạm để thêm ảnh', style: tt.bodyMedium),
              const SizedBox(height: 2),
              Text('Chụp ảnh hoặc chọn từ thư viện',
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(120))),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return SizedBox(
      width: 110,
      height: 110,
      child: Material(
        color: enabled
            ? cs.surfaceContainerHighest.withAlpha(100)
            : cs.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.withAlpha(80), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined,
                    size: 28, color: cs.onSurface.withAlpha(100)),
                const SizedBox(height: 4),
                Text('Thêm ảnh',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withAlpha(120),
                        )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.item,
    required this.isPicking,
    required this.onTapImage,
    required this.onRemove,
  });

  final UploadImageItem item;
  final bool isPicking;
  final VoidCallback onTapImage;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meta = AiProviders.getMeta(item.aiProvider);
    final hasProvider = item.aiProvider != null;

    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Tile image
              GestureDetector(
                onTap: onTapImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isPicking
                            ? AppColors.warning
                            : cs.outline.withAlpha(40),
                        width: isPicking ? 2.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: item.previewUrl.isNotEmpty
                        ? Image.network(
                            item.previewUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _fileFallback(item.file, cs),
                          )
                        : _fileFallback(item.file, cs),
                  ),
                ),
              ),
              // Provider badge (bottom-left)
              if (hasProvider)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(meta.colorValue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(meta.emoji, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 2),
                        Text(meta.shortName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            )),
                      ],
                    ),
                  ),
                ),
              // Remove button (top-right)
              if (onRemove != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fileFallback(File file, ColorScheme cs) {
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.surfaceLight,
        child: const Icon(Icons.broken_image_rounded, color: Colors.white),
      ),
    );
  }
}

class _ProviderPicker extends StatelessWidget {
  const _ProviderPicker({
    required this.currentProvider,
    required this.onSelect,
    required this.enableAiScan,
  });

  final String? currentProvider;
  final void Function(String?) onSelect;
  final bool enableAiScan;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final options = <_ProviderOption>[
      if (enableAiScan) ...[
        for (final p in AiProviders.all)
          _ProviderOption(
            provider: p,
            isSelected: currentProvider == p,
          ),
      ],
      _ProviderOption(
        provider: null, // Tắt AI
        isSelected: currentProvider == null,
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withAlpha(80), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
            child: Row(
              children: [
                Icon(Icons.smart_toy_outlined,
                    size: 14, color: cs.onSurface.withAlpha(180)),
                const SizedBox(width: 6),
                Text('🤖 CHỌN LOẠI QUÉT AI CHO ẢNH NÀY',
                    style: tt.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withAlpha(180),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final opt in options) _providerRow(context, opt, cs, tt),
        ],
      ),
    );
  }

  Widget _providerRow(
    BuildContext context,
    _ProviderOption opt,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final meta = AiProviders.getMeta(opt.provider);
    return InkWell(
      onTap: () => onSelect(opt.provider),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Text(meta.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt.provider == null
                        ? 'Không quét AI'
                        : meta.vietnameseName,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (opt.provider != null)
                    Text(meta.description,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurface.withAlpha(140))),
                ],
              ),
            ),
            if (opt.isSelected)
              const Icon(Icons.check_circle, color: AppColors.success, size: 18)
            else
              Icon(Icons.radio_button_unchecked,
                  color: cs.onSurface.withAlpha(80), size: 18),
          ],
        ),
      ),
    );
  }
}

class _ProviderOption {
  const _ProviderOption({required this.provider, required this.isSelected});
  final String? provider;
  final bool isSelected;
}

class _CaptionField extends StatelessWidget {
  const _CaptionField({
    required this.caption,
    required this.onChanged,
    required this.disabled,
    this.hint = 'Mô tả ảnh...',
  });
  final String caption;
  final void Function(String) onChanged;
  final bool disabled;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextField(
        controller: TextEditingController(text: caption)
          ..selection = TextSelection.collapsed(offset: caption.length),
        enabled: !disabled,
        onChanged: onChanged,
        maxLines: 1,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withAlpha(120),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10),
        ),
      ),
    );
  }
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet({required this.onCamera, required this.onGallery});
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
              width: 40,
              height: 4,
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
                  Text('Chọn nguồn ảnh',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  _SourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Chụp ảnh',
                    subtitle: 'Chụp ảnh minh chứng',
                    onTap: onCamera,
                  ),
                  const SizedBox(height: 10),
                  _SourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Chọn từ thư viện',
                    subtitle: 'Có thể chọn nhiều ảnh',
                    onTap: onGallery,
                  ),
                  const SizedBox(height: 16),
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
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
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
