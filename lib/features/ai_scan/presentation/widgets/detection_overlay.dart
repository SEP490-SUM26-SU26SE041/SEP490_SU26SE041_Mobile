import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import '../../../../core/theme/app_colors.dart';
import '../../data/mock_ai_scan.dart';

/// Stack overlay lên ảnh scan gốc:
///   1. Nếu có `annotatedImageBytes` (server trả sẵn ảnh đã vẽ bbox) — dùng luôn.
///   2. Nếu không → tự paint bbox từ `detections[].box`, scale theo `imageWidth`/`imageHeight`.
///
/// Mỗi `DetectionItem` được vẽ theo `DetectionCategory`:
///   - `gate` (gate model): nét đứt, màu xám — UI thứ cấp.
///   - `disease` (kết quả bệnh): nét liền, màu đậm theo `borderColor`.
class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
    this.annotatedImageBytes,
    this.borderColor = AppColors.warning,
  });

  final List<DetectionItem> detections;
  final int imageWidth;
  final int imageHeight;
  final List<int>? annotatedImageBytes;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    // Ưu tiên 1: server đã trả annotated image (chính xác 100%).
    if (annotatedImageBytes != null && annotatedImageBytes!.isNotEmpty) {
      return Image.memory(
        Uint8List.fromList(annotatedImageBytes!),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _FallbackError(),
      );
    }

    // Ưu tiên 2: tự paint bbox từ detections.
    final boxes = detections
        .where((d) => d.box != null)
        .toList(growable: false);
    if (boxes.isEmpty || imageWidth <= 0 || imageHeight <= 0) {
      return const _FallbackError();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return IgnorePointer(
          child: CustomPaint(
            painter: _BboxPainter(
              boxes: boxes,
              imageWidth: imageWidth,
              imageHeight: imageHeight,
              diseaseColor: borderColor,
            ),
          ),
        );
      },
    );
  }
}

class _FallbackError extends StatelessWidget {
  const _FallbackError();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.white54),
      ),
    );
  }
}

/// CustomPainter vẽ rectangles lên canvas theo tọa độ pixel ảnh gốc.
///
/// Quan trọng: bbox raw từ API tính theo ảnh GỐC (vd: ảnh 3024x4032).
/// Widget hiển thị (vd: 360x360) cùng `BoxFit.cover` → phải scale bbox theo
/// cùng cách Flutter scale ảnh để bbox nằm đúng vị trí vật lý.
class _BboxPainter extends CustomPainter {
  _BboxPainter({
    required this.boxes,
    required this.imageWidth,
    required this.imageHeight,
    required this.diseaseColor,
  });

  final List<DetectionItem> boxes;
  final int imageWidth;
  final int imageHeight;
  final Color diseaseColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final det in boxes) {
      final box = det.box!;
      if (box.originalWidth != imageWidth || box.originalHeight != imageHeight) {
        // Nếu bbox có size khác → dùng size của bbox (best-effort).
      }
      final rect = box.toRectInWidget(widgetSize: size, fit: BoxFit.cover);
      if (rect.isEmpty) continue;

      final isGate = det.category == DetectionCategory.gate;
      final color = isGate ? Colors.grey.shade400 : diseaseColor;

      // Vẽ border.
      final borderPaint = Paint()
        ..color = color
        ..strokeWidth = isGate ? 2.0 : 3.0
        ..style = PaintingStyle.stroke;
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      if (isGate) {
        // Gate: nét đứt, nhạt hơn.
        _drawDashedRRect(canvas, rrect, borderPaint, dash: 6, gap: 4);
      } else {
        canvas.drawRRect(rrect, borderPaint);
      }

      // Label chip ở góc trên-trái bbox.
      final title = _formatTitle(det);
      final subtitle = '${det.confidencePercent}%';
      _drawLabel(
        canvas,
        anchor: rect.topLeft,
        title: title,
        subtitle: subtitle,
        color: color,
      );
    }
  }

  String _formatTitle(DetectionItem det) {
    final raw = det.label;
    if (raw.isEmpty) return det.category == DetectionCategory.gate ? 'Gate' : 'Bệnh';
    final pretty = raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
    // Rút gọn còn 2-3 từ để label chip không quá dài.
    final parts = pretty.split(' ');
    if (parts.length > 3) return '${parts.take(3).join(' ')}…';
    return pretty;
  }

  void _drawDashedRRect(
    Canvas canvas,
    RRect rrect,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dash;
        final next = end.clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  void _drawLabel(
    Canvas canvas, {
    required Offset anchor,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 220);

    final subPainter = TextPainter(
      text: TextSpan(
        text: subtitle,
        style: TextStyle(
          color: Colors.white.withAlpha(220),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final w = (titlePainter.width > subPainter.width
            ? titlePainter.width
            : subPainter.width) +
        12;
    final h = titlePainter.height + subPainter.height + 8;

    // Đặt label ở phía trên bbox, nếu tràn mép trên thì đặt phía dưới.
    final placedTop = anchor.dy - h;
    final topY = placedTop >= 0 ? placedTop : anchor.dy;
    final leftX = anchor.dx < 0 ? 0.0 : anchor.dx;

    final rect = Rect.fromLTWH(leftX, topY, w, h);
    final bgPaint = Paint()..color = color;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rrect, bgPaint);

    titlePainter.paint(canvas, Offset(rect.left + 6, rect.top + 4));
    subPainter.paint(canvas, Offset(rect.left + 6, rect.top + 4 + titlePainter.height));
  }

  @override
  bool shouldRepaint(covariant _BboxPainter old) =>
      old.boxes != boxes ||
      old.imageWidth != imageWidth ||
      old.imageHeight != imageHeight ||
      old.diseaseColor != diseaseColor;
}