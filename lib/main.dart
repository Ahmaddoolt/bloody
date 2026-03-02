// file: lib/main.dart
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/layout/main_layout.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'core/widgets/custom_loader.dart';
import 'features/admin/screens/admin_home_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  await AppTheme.initTheme();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: const BloodyApp(),
    ),
  );
}

class BloodyApp extends StatelessWidget {
  const BloodyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Wareed',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _seenOnboarding = false;
  bool _isAuthenticated = false;
  bool _isAdmin = false;
  String _userType = 'receiver';

  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  /// 1. Sets up listener and checks initial state ONCE.
  /// This prevents the MainLayout from being destroyed during navigation.
  Future<void> _initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session == null) {
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _isLoading = false;
          });
        }
      } else {
        _handleUserSession(session.user);
      }
    });
  }

  /// 2. Fetches profile logic safely
  Future<void> _handleUserSession(User user) async {
    // Check Admin
    if (user.email == 'adminbloody2026@gmail.com') {
      if (mounted) {
        setState(() {
          _isAdmin = true;
          _isAuthenticated = true;
          _isLoading = false;
        });
      }
      return;
    }

    // Check Normal User Profile
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('user_type')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userType = data['user_type'] ?? 'receiver';
          _isAdmin = false;
          _isAuthenticated = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error("AuthGate._handleUserSession", e);
      if (mounted) {
        setState(() {
          _userType = 'receiver'; // Fallback
          _isAdmin = false;
          _isAuthenticated = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show Loader only during the very first boot
    if (_isLoading) {
      return const Scaffold(body: CustomLoader());
    }

    // Unauthenticated -> Login / Onboarding
    if (!_isAuthenticated) {
      return _seenOnboarding ? const LoginScreen() : const OnboardingScreen();
    }

    // Authenticated -> Admin Route
    if (_isAdmin) {
      return const AdminHomeScreen();
    }

    // Authenticated -> User Route (Safe, will not rebuild on pop)
    return MainLayout(userType: _userType);
  }
}
