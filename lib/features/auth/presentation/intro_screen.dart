import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/agritech_environment_background.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _subtitleCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _ambientCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _btnOpacity;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ambientCtrl, curve: Curves.easeInOut),
    );

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut),
    );

    _subtitleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _subtitleCtrl, curve: Curves.easeOut),
    );

    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _btnOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut),
    );

    // Stagger: text → subtitle → button
    Future.delayed(const Duration(milliseconds: 600), () => _textCtrl.forward());
    Future.delayed(const Duration(milliseconds: 900), () => _subtitleCtrl.forward());
    Future.delayed(const Duration(milliseconds: 1200), () => _btnCtrl.forward());
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _subtitleCtrl.dispose();
    _btnCtrl.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  void _enterApp() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AgritechEnvironmentBackground(
        mode: AgritechBackgroundMode.login,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _ambientCtrl,
            builder: (context, _) {
              return Stack(
                children: [
                  // Ambient floating elements
                  ..._buildAmbientElements(),

                  // Main content
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ===== LOGO =====
                          AnimatedBuilder(
                            animation: _logoCtrl,
                            builder: (context, _) => Opacity(
                              opacity: _logoOpacity.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: _buildLogo(isDark),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ===== TAGLINE =====
                          AnimatedBuilder(
                            animation: _textCtrl,
                            builder: (context, _) => Opacity(
                              opacity: _textOpacity.value,
                              child: Transform.translate(
                                offset: Offset(0, 15 * (1 - _textOpacity.value)),
                                child: Text(
                                  'Smart Nursery\nManagement System',
                                  textAlign: TextAlign.center,
                                  style: tt.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF1B5E20),
                                    height: 1.2,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ===== SUBTITLE =====
                          AnimatedBuilder(
                            animation: _subtitleCtrl,
                            builder: (context, _) => Opacity(
                              opacity: _subtitleOpacity.value,
                              child: Transform.translate(
                                offset: Offset(0, 10 * (1 - _subtitleOpacity.value)),
                                child: Text(
                                  'AI-Powered Agricultural Research Platform',
                                  textAlign: TextAlign.center,
                                  style: tt.bodyMedium?.copyWith(
                                    color: isDark
                                        ? Colors.white.withAlpha(153)
                                        : const Color(0xFF1B5E20).withAlpha(153),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 56),

                          // ===== ENTER BUTTON =====
                          AnimatedBuilder(
                            animation: _btnCtrl,
                            builder: (context, _) => Opacity(
                              opacity: _btnOpacity.value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - _btnOpacity.value)),
                                child: _buildEnterButton(tt, isDark),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ===== VERSION TAG =====
                          AnimatedBuilder(
                            animation: _btnCtrl,
                            builder: (context, _) => Opacity(
                              opacity: _btnOpacity.value * 0.6,
                              child: Text(
                                'v1.0.0  •  Premium Agritech',
                                style: tt.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.white.withAlpha(77)
                                      : const Color(0xFF1B5E20).withAlpha(77),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withAlpha((50 * _glowAnim.value).toInt()),
            blurRadius: 40,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: const Color(0xFF2E7D32).withAlpha((30 * _glowAnim.value).toInt()),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          'assets/images/snms_logo.png',
          width: 140,
          height: 140,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.eco_rounded, size: 70, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildEnterButton(TextTheme tt, bool isDark) {
    return GestureDetector(
      onTap: _enterApp,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withAlpha(77),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bat dau',
              style: tt.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAmbientElements() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : const Color(0xFF2E7D32);

    return [
      // Glowing ring behind logo
      Positioned.fill(
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, _) => Center(
            child: Container(
              width: 220 * _glowAnim.value,
              height: 220 * _glowAnim.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2E7D32).withAlpha(20),
                    const Color(0xFF2E7D32).withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // Floating data nodes
      for (var i = 0; i < 8; i++) _AmbientNode(index: i, ambientAnim: _glowAnim),

      // Top decorative line
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: AnimatedBuilder(
          animation: _textOpacity,
          builder: (context, _) => Opacity(
            opacity: _textOpacity.value * 0.3,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    baseColor.withAlpha(100),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // Bottom decorative line
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: AnimatedBuilder(
          animation: _textOpacity,
          builder: (context, _) => Opacity(
            opacity: _textOpacity.value * 0.3,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    baseColor.withAlpha(100),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

class _AmbientNode extends StatelessWidget {
  const _AmbientNode({required this.index, required this.ambientAnim});
  final int index;
  final Animation<double> ambientAnim;

  static double _lcg(int seed) {
    return ((seed * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff;
  }

  @override
  Widget build(BuildContext context) {
    final sx = _lcg(index);
    final sy = _lcg(index + 7);
    final t = ambientAnim.value;
    final opacity = _lcg(index + 14) * 0.5 + 0.1;
    final size = 6.0 + _lcg(index + 21) * 10;
    final type = index % 4;

    final icons = [
      Icons.eco_rounded,
      Icons.science_rounded,
      Icons.insights_rounded,
      Icons.grass_rounded,
    ];

    return AnimatedBuilder(
      animation: ambientAnim,
      builder: (context, _) {
        final y = sy + (t * 0.08 * (index.isEven ? 1 : -1));
        final x = sx + (t * 0.05 * (index.isOdd ? 1 : -1));
        final alpha = (opacity * (0.7 + t * 0.3) * 255).round().clamp(0, 255);

        return Positioned(
          left: MediaQuery.of(context).size.width * x,
          top: MediaQuery.of(context).size.height * y,
          child: Opacity(
            opacity: opacity * (0.7 + t * 0.3),
            child: Transform.scale(
              scale: 0.8 + t * 0.2,
              child: type == 0
                  ? Icon(icons[index % icons.length], size: size, color: const Color(0xFF2E7D32).withAlpha(alpha))
                  : Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2E7D32).withAlpha(alpha),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
