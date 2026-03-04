import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/layout/main_layout.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../references/button_patterns.dart';
import '../../../../admin/home/presentation/screens/admin_home_screen.dart';
import '../../data/auth_service.dart';
import '../../utils/auth_validators.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_field.dart';
import '../widgets/remember_me_toggle.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = true;

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.signIn(
      email: _emailController.text,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      final destination = result.userType == 'admin'
          ? const AdminHomeScreen()
          : MainLayout(userType: result.userType ?? 'receiver');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } else {
      _showErrorSnackBar(result.error ?? 'login_failed'.tr());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _staggered(0, child: AuthHeader(title: 'welcome_back'.tr())),
                SizedBox(height: AppSpacing.xl),
                _staggered(
                  1,
                  child: AuthTextField(
                    controller: _emailController,
                    label: 'email'.tr(),
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: AuthValidators.email,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                _staggered(
                  2,
                  child: PasswordField(
                    controller: _passwordController,
                    label: 'password'.tr(),
                    validator: AuthValidators.password,
                    textInputAction: TextInputAction.done,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                _staggered(
                  3,
                  child: RememberMeToggle(
                    value: _rememberMe,
                    onChanged: (val) => setState(() => _rememberMe = val),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                _staggered(
                  4,
                  child: AppButton(
                    label: 'login'.tr(),
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _signIn,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                _staggered(
                  5,
                  child: AppButton(
                    label: 'new_here'.tr(),
                    variant: AppButtonVariant.ghost,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _staggered(int index, {required Widget child}) {
    final begin = (index * 0.1).clamp(0.0, 0.6);
    final end = (begin + 0.4).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: _animController,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
