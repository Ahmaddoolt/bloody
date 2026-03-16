import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_constants.dart';
import 'core/layout/main_layout.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/home/presentation/screens/admin_home_screen.dart';
import 'features/shared/auth/presentation/providers/auth_provider.dart';
import 'features/shared/auth/presentation/screens/login_screen.dart';
import 'features/shared/auth/presentation/screens/onboarding_screen.dart';
import 'features/shared/auth/presentation/screens/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  await AppTheme.initTheme();

  FcmService.setupBackgroundHandler();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'),
        child: const BloodyApp(),
      ),
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
          title: 'Bloody',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _fcmInitialized = false;
  bool _hasCompletedInitialLoad = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    // Only show splash on initial app load, not during sign in/out operations
    if (authState.isLoading && !_hasCompletedInitialLoad) {
      return const SplashScreen();
    }

    _hasCompletedInitialLoad = true;

    if (!authState.isAuthenticated) {
      return authState.hasSeenOnboarding ? const LoginScreen() : const OnboardingScreen();
    }

    if (!_fcmInitialized) {
      _fcmInitialized = true;
      FcmService.initialize();
    }

    if (authState.isAdmin) {
      return const AdminHomeScreen();
    }

    return MainLayout(userType: authState.userType ?? 'receiver');
  }
}
