// file: lib/main.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/layout/main_layout.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/custom_loader.dart';
import 'features/admin/screens/admin_home_screen.dart'; // New Import
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
  Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_onboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: CustomLoader());
        }

        final session = snapshot.data?.session;

        if (session != null) {
          // 1. Check if Super Admin
          if (session.user.email == 'adminbloody2026@gmail.com') {
            return const AdminHomeScreen();
          }

          // 2. Otherwise, fetch profile for normal users
          return FutureBuilder<Map<String, dynamic>>(
            future: Supabase.instance.client
                .from('profiles')
                .select('user_type')
                .eq('id', session.user.id)
                .single(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: CustomLoader());
              }
              if (profileSnapshot.hasData) {
                final userType = profileSnapshot.data!['user_type'];
                return MainLayout(userType: userType ?? 'receiver');
              }
              // If profile fetch fails, assume receiver or fallback
              return const MainLayout(userType: 'receiver');
            },
          );
        }

        return FutureBuilder<bool>(
          future: _checkOnboardingStatus(),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: CustomLoader());
            }
            final seenOnboarding = onboardingSnapshot.data ?? false;
            return seenOnboarding
                ? const LoginScreen()
                : const OnboardingScreen();
          },
        );
      },
    );
  }
}
