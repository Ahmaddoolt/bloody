// file: lib/core/layout/main_layout.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../features/centers/screens/centers_screen.dart';
import '../../features/dashboard/screens/donor_dashboard_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart'
    hide DonorHomeScreen;
import '../../features/map/screens/receiver_map_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
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
      widget.userType == 'donor'
          ? const DonorHomeScreen()
          : const ReceiverHomeScreen(),
      const CentersScreen(),
      const LeaderboardScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // FIX: This line forces the widget to rebuild immediately when language changes
    // even if it's the parent of the Settings screen.
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
            label: 'home'.tr(), // Translated
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_hospital_outlined),
            selectedIcon:
                const Icon(Icons.local_hospital, color: AppTheme.darkRed),
            label: 'centers'.tr(), // Translated
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events_outlined),
            selectedIcon:
                const Icon(Icons.emoji_events, color: AppTheme.darkRed),
            label: 'legends'.tr(), // Translated
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings, color: AppTheme.darkRed),
            label: 'settings'.tr(), // Translated
          ),
        ],
      ),
    );
  }
}
