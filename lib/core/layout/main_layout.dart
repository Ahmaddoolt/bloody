// file: lib/core/layout/main_layout.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../actors/donor/dashboard/presentation/screens/donor_dashboard_screen.dart';
import '../../actors/donor/leaderboard/presentation/screens/leaderboard_screen.dart';
// ✅ NEW CLEAN ARCHITECTURE IMPORTS
import '../../actors/receiver/map_finder/presentation/screens/receiver_map_screen.dart';
import '../../shared/centers_list/presentation/screens/centers_screen.dart';
import '../../shared/settings/presentation/screens/settings_screen.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  final String userType;
  const MainLayout({super.key, required this.userType});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      widget.userType == 'donor' ? const DonorHomeScreen() : const ReceiverHomeScreen(),
      const CentersScreen(),
      const LeaderboardScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final currentLocale = context.locale;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: AppTheme.accentPink,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: AppTheme.darkRed),
            label: 'home'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_hospital_outlined),
            selectedIcon: const Icon(Icons.local_hospital, color: AppTheme.darkRed),
            label: 'centers'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon: const Icon(Icons.emoji_events, color: AppTheme.darkRed),
            label: 'legends'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings, color: AppTheme.darkRed),
            label: 'settings'.tr(),
          ),
        ],
      ),
    );
  }
}
