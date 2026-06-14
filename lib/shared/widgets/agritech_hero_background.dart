import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AgritechHeroBackground extends StatefulWidget {
  const AgritechHeroBackground({super.key});

  @override
  State<AgritechHeroBackground> createState() => _AgritechHeroBackgroundState();
}

class _AgritechHeroBackgroundState extends State<AgritechHeroBackground>
    with TickerProviderStateMixin {
  late AnimationController _sunController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _sunController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Layer 1: Sky Gradient
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0F1411),
                      Color(0xFF18201B),
                      Color(0xFF202A23),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFEAF6FF),
                      Color(0xFFF6FBFF),
                      Color(0xFFF7FAF5),
                    ],
                    stops: [0.0, 0.35, 1.0],
                  ),
          ),
        ),

        // Layer 2: Sunlight Glow (top-right, animated)
        AnimatedBuilder(
          animation: _sunController,
          builder: (context, child) {
            final offset = _sunController.value * 12;
            return Positioned(
              top: -40 + offset,
              right: -60 + (_sunController.value * 20),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withAlpha(isDark ? 20 : 30),
                      Colors.white.withAlpha(isDark ? 10 : 20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Layer 3: Organic shapes
        AnimatedBuilder(
          animation: _sunController,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _OrganicShapePainter(
                progress: _sunController.value,
                isDark: isDark,
              ),
            );
          },
        ),

        // Layer 4: Scientific overlay
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _ScientificGridPainter(
                progress: _particleController.value,
                isDark: isDark,
              ),
            );
          },
        ),

        // Floating particles
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _FloatingParticlesPainter(
                progress: _particleController.value,
                isDark: isDark,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OrganicShapePainter extends CustomPainter {
  _OrganicShapePainter({required this.progress, required this.isDark});
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [AppColors.primaryLight.withAlpha(6), Colors.transparent]
            : [AppColors.accent.withAlpha(12), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final wave = sin(progress * pi * 2) * 20;

    path.moveTo(0, size.height * 0.4);
    path.cubicTo(
      size.width * 0.3, size.height * 0.35 + wave,
      size.width * 0.7, size.height * 0.45 - wave,
      size.width, size.height * 0.38,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: isDark
            ? [AppColors.accent.withAlpha(4), Colors.transparent]
            : [AppColors.primaryLight.withAlpha(8), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path2 = Path();
    final wave2 = cos(progress * pi * 2) * 15;
    path2.moveTo(size.width * 0.5, size.height);
    path2.cubicTo(
      size.width * 0.6, size.height * 0.72 - wave2,
      size.width * 0.8, size.height * 0.65 + wave2,
      size.width, size.height * 0.6,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_OrganicShapePainter old) => old.progress != progress;
}

class _ScientificGridPainter extends CustomPainter {
  _ScientificGridPainter({required this.progress, required this.isDark});
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? AppColors.accent : AppColors.primary).withAlpha(6)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    final offset = progress * spacing;

    for (double x = offset % spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = offset % spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final dotPaint = Paint()
      ..color = (isDark ? AppColors.accent : AppColors.primary).withAlpha(8)
      ..style = PaintingStyle.fill;

    for (double x = spacing / 2; x < size.width; x += spacing * 2) {
      for (double y = spacing / 2; y < size.height; y += spacing * 2) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ScientificGridPainter old) => old.progress != progress;
}

class _FloatingParticlesPainter extends CustomPainter {
  _FloatingParticlesPainter({required this.progress, required this.isDark});
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = (isDark ? AppColors.accent : AppColors.primary).withAlpha(13);

    final particles = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.5),
      Offset(size.width * 0.4, size.height * 0.7),
    ];

    for (int i = 0; i < particles.length; i++) {
      final base = particles[i];
      final phase = i / particles.length;
      final y = base.dy + sin((progress + phase) * pi * 2) * 20;
      final x = base.dx + cos((progress + phase * 0.5) * pi * 2) * 10;
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(_FloatingParticlesPainter old) => old.progress != progress;
}
