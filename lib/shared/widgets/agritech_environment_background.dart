import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum AgritechBackgroundMode {
  login,
  dashboard,
  compact,
  none,
}

class AgritechEnvironmentBackground extends StatelessWidget {
  const AgritechEnvironmentBackground({
    super.key,
    this.mode = AgritechBackgroundMode.dashboard,
    this.accentColor,
    this.child = const SizedBox.shrink(),
  });

  final AgritechBackgroundMode mode;
  final Color? accentColor;
  final Widget child;

  bool get showSunlight => mode == AgritechBackgroundMode.login || mode == AgritechBackgroundMode.dashboard;
  bool get showScientific => mode != AgritechBackgroundMode.none;
  bool get showParticles => mode == AgritechBackgroundMode.dashboard || mode == AgritechBackgroundMode.login;
  bool get showOrganic => mode != AgritechBackgroundMode.none && mode != AgritechBackgroundMode.compact;
  bool get showEnhancedParticles => mode == AgritechBackgroundMode.dashboard;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? (isDark ? AppColors.accent : AppColors.primary);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0A0F0D),
                      Color(0xFF0D1510),
                      Color(0xFF111A14),
                    ],
                    stops: [0.0, 0.4, 1.0],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE8F5E9),
                      Color(0xFFF1F8E9),
                      Color(0xFFF5F7F0),
                    ],
                    stops: [0.0, 0.35, 1.0],
                  ),
          ),
        ),
        if (showSunlight)
          _EnhancedSunlightGlow(isDark: isDark, accent: accent),
        if (showScientific)
          _ScientificGrid(isDark: isDark, accent: accent),
        if (showOrganic)
          _OrganicShapes(isDark: isDark, accent: accent),
        if (showParticles)
          _EnhancedFloatingParticles(isDark: isDark, accent: accent),
        if (showEnhancedParticles)
          _AgriParticlesLayer(isDark: isDark, accent: accent),
        if (mode == AgritechBackgroundMode.login)
          _HeroOverlay(isDark: isDark),
        child,
      ],
    );
  }
}

class _EnhancedSunlightGlow extends StatefulWidget {
  const _EnhancedSunlightGlow({required this.isDark, required this.accent});
  final bool isDark;
  final Color accent;

  @override
  State<_EnhancedSunlightGlow> createState() => _EnhancedSunlightGlowState();
}

class _EnhancedSunlightGlowState extends State<_EnhancedSunlightGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned(
              top: -80 + (_ctrl.value * 20),
              right: -100 + (_ctrl.value * 30),
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.accent.withAlpha(widget.isDark ? 25 : 40),
                      widget.accent.withAlpha(widget.isDark ? 12 : 20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 60 + (_ctrl.value * 10),
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withAlpha(widget.isDark ? 15 : 25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScientificGrid extends StatelessWidget {
  const _ScientificGrid({required this.isDark, required this.accent});
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _GridPainter(isDark: isDark, accent: accent));
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.isDark, required this.accent});
  final bool isDark;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withAlpha(isDark ? 5 : 3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final dotPaint = Paint()
      ..color = accent.withAlpha(isDark ? 8 : 5)
      ..style = PaintingStyle.fill;

    for (double x = spacing / 2; x < size.width; x += spacing * 2) {
      for (double y = spacing / 2; y < size.height; y += spacing * 2) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _OrganicShapes extends StatefulWidget {
  const _OrganicShapes({required this.isDark, required this.accent});
  final bool isDark;
  final Color accent;

  @override
  State<_OrganicShapes> createState() => _OrganicShapesState();
}

class _OrganicShapesState extends State<_OrganicShapes>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _OrganicPainter(progress: _ctrl.value, isDark: widget.isDark, accent: widget.accent),
        );
      },
    );
  }
}

class _OrganicPainter extends CustomPainter {
  _OrganicPainter({required this.progress, required this.isDark, required this.accent});
  final double progress;
  final bool isDark;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [accent.withAlpha(14), Colors.transparent]
            : [accent.withAlpha(22), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final wave = sin(progress * pi * 2) * 18;
    path.moveTo(0, size.height * 0.38);
    path.cubicTo(
      size.width * 0.25, size.height * 0.32 + wave,
      size.width * 0.6, size.height * 0.42 - wave,
      size.width, size.height * 0.35,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, p1);

    final p2 = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: isDark
            ? [accent.withAlpha(10), Colors.transparent]
            : [accent.withAlpha(18), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path2 = Path();
    final wave2 = cos(progress * pi * 2) * 12;
    path2.moveTo(size.width * 0.4, size.height);
    path2.cubicTo(
      size.width * 0.55, size.height * 0.70 - wave2,
      size.width * 0.75, size.height * 0.62 + wave2,
      size.width, size.height * 0.58,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(_OrganicPainter old) => old.progress != progress;
}

class _EnhancedFloatingParticles extends StatefulWidget {
  const _EnhancedFloatingParticles({required this.isDark, required this.accent});
  final bool isDark;
  final Color accent;

  @override
  State<_EnhancedFloatingParticles> createState() => _EnhancedFloatingParticlesState();
}

class _EnhancedFloatingParticlesState extends State<_EnhancedFloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlesPainter(progress: _ctrl.value, isDark: widget.isDark, accent: widget.accent),
        );
      },
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({required this.progress, required this.isDark, required this.accent});
  final double progress;
  final bool isDark;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withAlpha(isDark ? 22 : 18);

    final positions = [
      Offset(size.width * 0.15, size.height * 0.28),
      Offset(size.width * 0.72, size.height * 0.12),
      Offset(size.width * 0.88, size.height * 0.52),
      Offset(size.width * 0.38, size.height * 0.72),
    ];

    for (int i = 0; i < positions.length; i++) {
      final base = positions[i];
      final phase = i / positions.length;
      final y = base.dy + sin((progress + phase) * pi * 2) * 18;
      final x = base.dx + cos((progress + phase * 0.5) * pi * 2) * 8;
      canvas.drawCircle(Offset(x, y), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => old.progress != progress;
}

class _AgriParticlesLayer extends StatefulWidget {
  const _AgriParticlesLayer({required this.isDark, required this.accent});
  final bool isDark;
  final Color accent;

  @override
  State<_AgriParticlesLayer> createState() => _AgriParticlesLayerState();
}

class _AgriParticlesLayerState extends State<_AgriParticlesLayer>
    with TickerProviderStateMixin {
  late AnimationController _dustCtrl;
  late AnimationController _leafCtrl;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _dustCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _leafCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _dustCtrl.dispose();
    _leafCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_dustCtrl, _leafCtrl, _waveCtrl]),
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _AgriParticlesPainter(
            dustProgress: _dustCtrl.value,
            leafProgress: _leafCtrl.value,
            waveProgress: _waveCtrl.value,
            isDark: widget.isDark,
            accent: widget.accent,
          ),
        );
      },
    );
  }
}

class _AgriParticlesPainter extends CustomPainter {
  _AgriParticlesPainter({
    required this.dustProgress,
    required this.leafProgress,
    required this.waveProgress,
    required this.isDark,
    required this.accent,
  });
  final double dustProgress;
  final double leafProgress;
  final double waveProgress;
  final bool isDark;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    _paintDustParticles(canvas, size);
    _paintFloatingLeaves(canvas, size);
  }

  void _paintDustParticles(Canvas canvas, Size size) {
    final dustPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withAlpha(isDark ? 12 : 10);

    for (int i = 0; i < 20; i++) {
      final baseX = size.width * (i / 20.0);
      final speed = 0.3 + (i % 3) * 0.25;
      final x = (baseX + dustProgress * size.width * speed) % size.width;
      final baseY = size.height * (0.1 + (i % 5) * 0.15);
      final y = baseY + sin((dustProgress + i * 0.3) * pi * 2) * 20;
      final r = 1.0 + (i % 3) * 0.8;
      canvas.drawCircle(Offset(x, y), r, dustPaint);
    }
  }

  void _paintFloatingLeaves(Canvas canvas, Size size) {
    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withAlpha(isDark ? 18 : 14);

    for (int i = 0; i < 6; i++) {
      final baseX = size.width * (0.1 + (i % 4) * 0.22);
      final phase = i / 6.0;
      final x = baseX + cos((leafProgress + phase) * pi * 2) * 40;
      final baseY = size.height * (0.15 + (i % 3) * 0.28);
      final y = baseY + sin((leafProgress + phase) * pi * 2) * 25;
      final leafPath = Path();
      leafPath.moveTo(x, y - 4);
      leafPath.quadraticBezierTo(x + 4, y, x, y + 4);
      leafPath.quadraticBezierTo(x - 4, y, x, y - 4);
      canvas.drawPath(leafPath, leafPaint);
    }
  }

  @override
  bool shouldRepaint(_AgriParticlesPainter old) =>
      old.dustProgress != dustProgress ||
      old.leafProgress != leafProgress ||
      old.waveProgress != waveProgress;
}

class _HeroOverlay extends StatelessWidget {
  const _HeroOverlay({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.8, -0.5),
            radius: 1.2,
            colors: [
              AppColors.primary.withAlpha(isDark ? 14 : 18),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
