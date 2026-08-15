import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _redirectHandled = false;

  late AnimationController _staggerController;
  late Animation<double> _logoAnim;
  late Animation<double> _titleAnim;
  late Animation<double> _subtitleAnim;
  late Animation<double> _cardAnim;
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
    _cardAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.50, 0.80, curve: Curves.easeOutCubic)),
    );

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
    _plantController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          UserRole.researcher => '/dashboard',
          UserRole.student => '/student/dashboard',
          UserRole.technician => '/tech/dashboard',
        };
        context.go(dashboard);
      });
    }

    // Reset redirect flag when user is unauthenticated (logged out)
    if (authState is AuthUnauthenticated || authState is AuthInitial) {
      _redirectHandled = false;
    }

    // Toast error when login fails (in addition to inline error banner).
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is AuthError && prev is! AuthError) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sai tài khoản hoặc mật khẩu. Vui lòng thử lại.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      body: AgritechEnvironmentBackground(
        mode: AgritechBackgroundMode.login,
        child: SafeArea(
          child: Column(
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

              const SizedBox(height: AppSpacing.lg),
            ],
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
                              'Chào mừng bạn!',
                              style: tt.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            'Đăng nhập để tiếp tục',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface.withAlpha(140),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Divider ngăn cách header & form
                        Container(
                          height: 1,
                          margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                          color: cs.outline.withAlpha(40),
                        ),

                        // Email field
                        _buildField(
                          label: 'Email',
                          hint: 'khoa.researcher@snms.vn',
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                            if (!v.contains('@')) return 'Email không hợp lệ';
                            return null;
                          },
                          tt: tt,
                          cs: cs,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Password field
                        _buildField(
                          label: 'Mật khẩu',
                          hint: 'Nhập mật khẩu của bạn',
                          icon: Icons.lock_outlined,
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                            if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                            return null;
                          },
                          tt: tt,
                          cs: cs,
                          isDark: isDark,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: cs.onSurface.withAlpha(128),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

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
                              height: 54,
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
                                            'Đăng nhập',
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
}
