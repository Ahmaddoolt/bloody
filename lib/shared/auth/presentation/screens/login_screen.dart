// file: lib/features/auth/screens/login_screen.dart
import 'package:bloody/shared/auth/presentation/screens/signup_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../actors/admin/home/presentation/screens/admin_home_screen.dart';
import '../../../../core/layout/main_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_loader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Remember Me State
  bool _rememberMe = true;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);

      // 1. Attempt Sign In
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // 2. If successful, check user type for navigation
      if (res.user != null) {
        if (!mounted) return;

        // FIX: Check for Super Admin FIRST
        if (email == 'adminbloody2026@gmail.com') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
            (route) => false,
          );
          return; // Stop execution here for admin
        }

        // For regular users, fetch profile
        final profile =
            await supabase.from('profiles').select('user_type').eq('id', res.user!.id).single();

        final userType = profile['user_type'] ?? 'receiver';

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => MainLayout(userType: userType),
            ),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('login_failed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.bloodtype, size: 100, color: AppTheme.primaryRed),
              const SizedBox(height: 20),
              Text(
                'welcome_back'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isDark ? Colors.white : AppTheme.darkRed,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'email'.tr(),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'password'.tr(),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: AppTheme.primaryRed,
                    side: BorderSide(
                      color: isDark ? Colors.white70 : Colors.grey,
                      width: 2,
                    ),
                    onChanged: (val) => setState(() => _rememberMe = val ?? true),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Text("remember_me".tr()),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const CustomLoader(size: 20, color: Colors.white)
                    : Text('login'.tr()),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                child: Text('new_here'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
