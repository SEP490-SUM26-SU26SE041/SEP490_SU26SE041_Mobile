import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

class PlantPhotoGallery extends StatelessWidget {
  const PlantPhotoGallery({super.key, this.maxPhotos = 6, this.showSectionTitle = true});

  final int maxPhotos;
  final bool showSectionTitle;

  @override
  Widget build(BuildContext context) {
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
                Text('Hình ảnh cây gần đây', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 0,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
