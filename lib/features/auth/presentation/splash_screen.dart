import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _enterController;
  late Animation<double> _enterOpacity;
  late Animation<double> _enterScale;

  late AnimationController _exitController;
  late Animation<double> _exitOpacity;
  late Animation<double> _exitScale;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _enterOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );
    _enterScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
    );

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _exitOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _enterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _isExiting = true);
            _exitController.forward();
          }
        });
      }
    });

    _exitController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.go('/login');
      }
    });

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_enterController, _exitController]),
          builder: (context, child) {
            final opacity = _isExiting ? _exitOpacity.value : _enterOpacity.value;
            final scale = _isExiting ? _exitScale.value : _enterScale.value;
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/snms_logo_splash.svg',
                width: 220,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 32,
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.accent.withAlpha(51),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
