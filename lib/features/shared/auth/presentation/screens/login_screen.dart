import 'package:bloody/core/layout/main_layout.dart';
import 'package:bloody/core/theme/app_colors.dart';
import 'package:bloody/core/theme/app_spacing.dart';
import 'package:bloody/core/widgets/app_loading_indicator.dart';
import 'package:bloody/features/admin/home/presentation/screens/admin_home_screen.dart';
import 'package:bloody/features/shared/auth/presentation/providers/auth_provider.dart';
import 'package:bloody/features/shared/auth/presentation/widgets/password_field.dart';
import 'package:bloody/features/shared/auth/presentation/widgets/remember_me_toggle.dart';
import 'package:bloody/features/shared/auth/utils/auth_validators.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );

    if (!mounted) return;

    if (result.success) {
      final authState = ref.read(authNotifierProvider);
      final destination = authState.isAdmin
          ? const AdminHomeScreen()
          : MainLayout(userType: authState.userType ?? 'receiver');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } else {
      _showError(result.error ?? 'login_failed'.tr());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: AppSpacing.page.copyWith(top: 48, bottom: 32),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(colorScheme),
                            const SizedBox(height: 48),
                            _EmailField(
                              controller: _emailController,
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: 16),
                            PasswordField(
                              controller: _passwordController,
                              label: 'password'.tr(),
                              validator: AuthValidators.password,
                              textInputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: 12),
                            RememberMeToggle(
                              value: _rememberMe,
                              onChanged: isLoading
                                  ? (_) {}
                                  : (val) => setState(() => _rememberMe = val),
                            ),
                            const SizedBox(height: 32),
                            _PrimaryButton(
                              label: 'login'.tr(),
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _signIn,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const SignupScreen(),
                                          ),
                                        ),
                                child: Text(
                                  'new_here'.tr(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.bloodtype_rounded,
            size: 32,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'welcome_back'.tr(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _EmailField({
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      validator: AuthValidators.email,
      decoration: InputDecoration(
        labelText: 'email'.tr(),
        prefixIcon: Icon(
          Icons.email_outlined,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null
          ? null
          : (_) => setState(() => _scale = 0.97),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() => _scale = 1.0);
              widget.onPressed?.call();
            },
      onTapCancel:
          widget.onPressed == null ? null : () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: widget.isLoading
                ? const AppLoadingIndicator(
                    size: 20,
                    strokeWidth: 2,
                    color: Colors.white,
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
