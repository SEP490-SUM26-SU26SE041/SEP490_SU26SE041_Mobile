import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Hero section phía trên của màn hình AI Scan:
///   - Ảnh cây + overlay scanning frame + scan line animation
///   - Nút "Chụp ảnh / Tải lên" ở dưới
///
/// [imageUrl] — URL hoặc local file path.
/// [isResult] — true: hiện ảnh đã scan, ẩn button. false: hiện ảnh placeholder + button.
class ScanHeroSection extends StatefulWidget {
  const ScanHeroSection({
    super.key,
    required this.imageUrl,
    required this.onScanPressed,
    this.isResult = false,
  });

  final String imageUrl;
  final VoidCallback onScanPressed;
  final bool isResult;

  @override
  State<ScanHeroSection> createState() => _ScanHeroSectionState();
}

class _ScanHeroSectionState extends State<ScanHeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh — network hoặc local file
            _buildImage(),
            // Overlay đen mờ
            ColoredBox(color: Colors.black.withAlpha(26)),
            // Scanning frame (chỉ khi chưa có result)
            if (!widget.isResult) ...[
              Center(
                child: SizedBox(
                  width: 192, height: 192,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFAEF67B).withAlpha(204),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const _CornerBracket(corner: Corner.topLeft),
                      const _CornerBracket(corner: Corner.topRight),
                      const _CornerBracket(corner: Corner.bottomLeft),
                      const _CornerBracket(corner: Corner.bottomRight),
                      AnimatedBuilder(
                        animation: _ctrl,
                        builder: (_, _) => Positioned(
                          top: _ctrl.value * 190,
                          left: 0, right: 0,
                          child: _ScanLine(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // CTA button (chỉ khi chưa có result)
            if (!widget.isResult)
              Positioned(
                left: 0, right: 0, bottom: 24,
                child: Center(
                  child: FilledButton.icon(
                    onPressed: widget.onScanPressed,
                    icon: const Icon(Icons.center_focus_strong_rounded, size: 22),
                    label: const Text(
                      'Chụp ảnh / Tải lên',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, height: 24 / 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: const StadiumBorder(),
                      elevation: 8,
                      shadowColor: Colors.black.withAlpha(60),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = widget.imageUrl;

    // Local file path (starts with / or contains pathSeparator)
    final isLocal = url.startsWith('/') || url.contains(Platform.pathSeparator);

    if (isLocal) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: AppColors.surfaceLight),
      errorWidget: (context, url, error) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.accent.withAlpha(60),
      child: const Icon(Icons.eco_rounded, size: 64, color: Colors.white),
    );
  }
}

enum Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({required this.corner});
  final Corner corner;

  @override
  Widget build(BuildContext context) {
    const double len = 32;
    const double thick = 4;
    final color = const Color(0xFFAEF67B);
    final alignment = switch (corner) {
      Corner.topLeft => Alignment.topLeft,
      Corner.topRight => Alignment.topRight,
      Corner.bottomLeft => Alignment.bottomLeft,
      Corner.bottomRight => Alignment.bottomRight,
    };
    final isLeft = corner == Corner.topLeft || corner == Corner.bottomLeft;
    final isTop = corner == Corner.topLeft || corner == Corner.topRight;
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: len,
        height: len,
        child: CustomPaint(painter: _CornerPainter(color, thick, isLeft, isTop)),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.color, this.thick, this.isLeft, this.isTop);
  final Color color;
  final double thick;
  final bool isLeft;
  final bool isTop;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeCap = StrokeCap.square
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    // Vertical bar
    canvas.drawLine(
      Offset(isLeft ? 0 : w, isTop ? 0 : h),
      Offset(isLeft ? 0 : w, isTop ? thick : h - thick),
      p,
    );
    // Horizontal bar
    canvas.drawLine(
      Offset(isLeft ? 0 : w, isTop ? 0 : h),
      Offset(isLeft ? thick : w - thick, isTop ? 0 : h),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) =>
      old.color != color || old.thick != thick;
}

class _ScanLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: const Color(0xFFAEF67B).withAlpha(128),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF93D962).withAlpha(204),
            blurRadius: 15,
          ),
        ],
      ),
    );
  }
}