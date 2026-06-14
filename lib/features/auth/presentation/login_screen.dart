import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/agritech_environment_background.dart';
import '../../../shared/models/user_model.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  int _selectedQuickRole = -1;
  bool _redirectHandled = false;

  late AnimationController _staggerController;
  late Animation<double> _logoAnim;
  late Animation<double> _titleAnim;
  late Animation<double> _subtitleAnim;
  late Animation<double> _badgeAnim;
  late Animation<double> _cardAnim;
  late Animation<double> _demoAnim;

  late AnimationController _ambientController;

  late AnimationController _plantController;
  late Animation<double> _plantAnim;

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.0, 0.20, curve: Curves.easeOut)),
    );
    _titleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.15, 0.35, curve: Curves.easeOut)),
    );
    _subtitleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.25, 0.45, curve: Curves.easeOut)),
    );
    _badgeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.35, 0.55, curve: Curves.easeOut)),
    );
    _cardAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.50, 0.80, curve: Curves.easeOutCubic)),
    );
    _demoAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.75, 1.0, curve: Curves.easeOut)),
    );

    _ambientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _plantController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _plantAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _plantController, curve: Curves.easeOutCubic),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _ambientController.dispose();
    _plantController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onQuickLogin(_QuickAccount acc) {
    setState(() => _selectedQuickRole = acc.index);
    _emailController.text = acc.email;
    _passwordController.text = 'demo123';
    _plantController.forward(from: 0);
    _login();
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  bool get _hasText => _emailController.text.isNotEmpty || _passwordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final isError = authState is AuthError;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Redirect to dashboard when authenticated (once per login)
    if (authState is AuthAuthenticated && !_redirectHandled) {
      _redirectHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final role = authState.user.role;
        final dashboard = switch (role) {
          UserRole.researcher  => '/dashboard',
          UserRole.student    => '/student/dashboard',
          UserRole.technician => '/tech/dashboard',
          UserRole.farmManager => '/fm/dashboard',
          UserRole.admin      => '/admin/dashboard',
        };
        context.go(dashboard);
      });
    }

    // Reset redirect flag when user is unauthenticated (logged out)
    if (authState is AuthUnauthenticated || authState is AuthInitial) {
      _redirectHandled = false;
    }

    return Scaffold(
      body: AgritechEnvironmentBackground(
        mode: AgritechBackgroundMode.login,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _ambientController,
            builder: (context, _) {
              return Stack(
                children: [
                  // Ambient floating leaves — pass controller so AnimatedBuilder works
                  ...List.generate(6, (i) => _FloatingLeaf(index: i, ambientCtrl: _ambientController)),

                  Column(
                    children: [
                      // Top: Logo header
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _logoAnim,
                            builder: (context, _) => Opacity(
                              opacity: _logoAnim.value,
                              child: Transform.scale(
                                scale: 0.7 + (_logoAnim.value * 0.3),
                                child: _buildHeader(isDark),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Middle: Form card
                      Expanded(
                        flex: 3,
                        child: AnimatedBuilder(
                          animation: _cardAnim,
                          builder: (context, _) => Opacity(
                            opacity: _cardAnim.value,
                            child: _buildCard(isDark, isLoading, isError, authState),
                          ),
                        ),
                      ),

                      // Bottom: Quick Access
                      AnimatedBuilder(
                        animation: _demoAnim,
                        builder: (context, _) => Opacity(
                          opacity: _demoAnim.value,
                          child: _buildQuickAccess(),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Clean SVG icon mark
        AnimatedBuilder(
          animation: _logoAnim,
          builder: (context, _) => Opacity(
            opacity: _logoAnim.value,
            child: Transform.scale(
              scale: 0.7 + (_logoAnim.value * 0.3),
              child: SvgPicture.asset(
                'assets/images/snms_icon.svg',
                width: 64,
                height: 64,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        AnimatedBuilder(
          animation: _titleAnim,
          builder: (context, _) => Opacity(
            opacity: _titleAnim.value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - _titleAnim.value)),
              child: Text(
                'SNMS',
                style: tt.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),

        AnimatedBuilder(
          animation: _subtitleAnim,
          builder: (context, _) => Opacity(
            opacity: _subtitleAnim.value,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - _subtitleAnim.value)),
              child: Text(
                'Smart Nursery Management',
                style: tt.bodySmall?.copyWith(
                  color: AppColors.primaryLight,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(bool isDark, bool isLoading, bool isError, AuthState authState) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark.withAlpha(255) : Colors.white.withAlpha(255),
                  borderRadius: BorderRadius.circular(AppRadius.sheet),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark.withAlpha(153) : Colors.grey.shade200,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 38 : 20),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Welcome header
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Chao mung ban!',
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            'Dang nhap de tiep tuc',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface.withAlpha(128),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Email field
                        _buildField(
                          label: 'Email',
                          hint: 'khoa.researcher@snms.vn',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Vui long nhap email';
                            if (!v.contains('@')) return 'Email khong hop le';
                            return null;
                          },
                          tt: tt,
                          cs: cs,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Password field
                        _buildField(
                          label: 'Mat khau',
                          hint: '',
                          icon: Icons.lock_outlined,
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Vui long nhap mat khau';
                            return null;
                          },
                          tt: tt,
                          cs: cs,
                          isDark: isDark,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: cs.onSurface.withAlpha(102),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Quen mat khau?',
                              style: tt.labelMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Error message
                        if (isError) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(12),
                              borderRadius: BorderRadius.circular(AppRadius.small),
                              border: Border.all(color: AppColors.error.withAlpha(30)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    (authState as AuthError).message,
                                    style: tt.bodySmall?.copyWith(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Login button
                        AnimatedBuilder(
                          animation: _plantController,
                          builder: (context, _) {
                            return SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: AppColors.primary.withAlpha(102),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.medium),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Transform.scale(
                                            scale: 0.8 + (_plantAnim.value * 0.4),
                                            child: Icon(
                                              Icons.eco_rounded,
                                              size: 18 + (_plantAnim.value * 4),
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            'Dang nhap',
                                            style: tt.labelLarge?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
    required TextTheme tt,
    required ColorScheme cs,
    required bool isDark,
    Widget? suffix,
  }) {
    final hasText = controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: tt.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: hasText ? AppColors.primary : cs.onSurface.withAlpha(153),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : const Color(0xFFF5F7F4),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: hasText
                  ? AppColors.primary.withAlpha(102)
                  : (isDark ? AppColors.borderDark : Colors.grey.shade200),
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            validator: validator,
            onChanged: (_) => setState(() {}),
            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(77)),
              prefixIcon: Icon(icon, size: 20, color: hasText ? AppColors.primary : cs.onSurface.withAlpha(102)),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccess() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    final accounts = [
      _QuickAccount(index: 0, email: 'khoa.researcher@snms.vn', role: 'Researcher', color: AppColors.primary, icon: Icons.science_rounded),
      _QuickAccount(index: 1, email: 'lan.student@snms.vn', role: 'Student', color: AppColors.info, icon: Icons.school_rounded),
      _QuickAccount(index: 2, email: 'huong.tech@snms.vn', role: 'Technician', color: AppColors.warning, icon: Icons.build_rounded),
      _QuickAccount(index: 3, email: 'duc.manager@snms.vn', role: 'Farm Manager', color: AppColors.success, icon: Icons.agriculture_rounded),
      _QuickAccount(index: 4, email: 'admin@snms.vn', role: 'Admin', color: AppColors.accent, icon: Icons.admin_panel_settings_rounded),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(child: Container(height: 1, color: (isDark ? Colors.white : const Color(0xFF1B5E20)).withAlpha(51))),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.flash_on_rounded, size: 14, color: AppColors.primary.withAlpha(153)),
              const SizedBox(width: 4),
              Text(
                'Quick Access',
                style: tt.labelSmall?.copyWith(
                  color: (isDark ? Colors.white : const Color(0xFF1B5E20)).withAlpha(153),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Container(height: 1, color: (isDark ? Colors.white : const Color(0xFF1B5E20)).withAlpha(51))),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) => _QuickAccessChip(
              account: accounts[index],
              isSelected: _selectedQuickRole == index,
              onTap: () => _onQuickLogin(accounts[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAccount {
  final int index;
  final String email;
  final String role;
  final Color color;
  final IconData icon;
  const _QuickAccount({
    required this.index,
    required this.email,
    required this.role,
    required this.color,
    required this.icon,
  });
}

class _QuickAccessChip extends StatefulWidget {
  const _QuickAccessChip({required this.account, required this.isSelected, required this.onTap});
  final _QuickAccount account;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_QuickAccessChip> createState() => _QuickAccessChipState();
}

class _QuickAccessChipState extends State<_QuickAccessChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Transform.scale(
        scale: _scaleAnim.value,
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) { _controller.reverse(); widget.onTap(); },
          onTapCancel: () => _controller.reverse(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.account.color.withAlpha(25)
                  : (isDark ? AppColors.cardDark.withAlpha(220) : Colors.white.withAlpha(240)),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(
                color: widget.isSelected
                    ? widget.account.color.withAlpha(128)
                    : (isDark ? AppColors.borderDark.withAlpha(102) : Colors.grey.shade200),
                width: widget.isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.account.color.withAlpha(widget.isSelected ? 20 : 10),
                  blurRadius: widget.isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.account.color.withAlpha(widget.isSelected ? 35 : 20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.account.icon,
                    size: 20,
                    color: widget.account.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.account.role,
                  style: tt.labelSmall?.copyWith(
                    color: widget.isSelected
                        ? widget.account.color
                        : (isDark ? Colors.white.withAlpha(179) : const Color(0xFF1B5E20).withAlpha(179)),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  widget.account.email,
                  style: tt.bodySmall?.copyWith(
                    color: (isDark ? Colors.white : const Color(0xFF1B5E20)).withAlpha(102),
                    fontSize: 8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingLeaf extends StatefulWidget {
  const _FloatingLeaf({required this.index, required this.ambientCtrl});
  final int index;
  final AnimationController ambientCtrl;

  @override
  State<_FloatingLeaf> createState() => _FloatingLeafState();
}

class _FloatingLeafState extends State<_FloatingLeaf> {
  late double _sx;
  late double _sy;
  late double _sz;

  static double _lcg(int seed) {
    return ((seed * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff;
  }

  @override
  void initState() {
    super.initState();
    _sx = _lcg(widget.index);
    _sy = _lcg(widget.index + 7) / 2.5;
    _sz = 12.0 + _lcg(widget.index + 14) * 8;
  }

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.eco_rounded,
      Icons.grass_rounded,
      Icons.spa_rounded,
      Icons.park_rounded,
      Icons.local_florist_rounded,
      Icons.eco_outlined,
    ];

    return AnimatedBuilder(
      animation: widget.ambientCtrl,
      builder: (context, _) {
        final t = widget.ambientCtrl.value;
        final pi = 3.141592653589793;
        final y = _sy + t * 0.12;
        final x = _sx + math.sin(t * pi * 2 + widget.index) * 0.025;
        final alpha = (0.3 * (0.5 + t * 0.5) * 255).round().clamp(0, 255);
        final angle = t * pi * 0.3 + widget.index * 0.5;

        final size = MediaQuery.of(context).size;
        return Positioned(
          left: size.width * x,
          top: size.height * y,
          child: Opacity(
            opacity: (0.3 * (0.5 + t * 0.5)).clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: angle,
              child: Icon(
                icons[widget.index % icons.length],
                size: _sz,
                color: AppColors.primary.withAlpha(alpha),
              ),
            ),
          ),
        );
      },
    );
  }
}
