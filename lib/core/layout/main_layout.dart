// file: lib/core/layout/main_layout.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/donor/dashboard/presentation/screens/donor_dashboard_screen.dart';
import '../../features/donor/leaderboard/presentation/screens/leaderboard_screen.dart';
// ✅ NEW CLEAN ARCHITECTURE IMPORTS
import '../../features/receiver/map_finder/presentation/screens/receiver_map_screen.dart';
import '../../features/shared/centers_list/presentation/screens/centers_screen.dart';
import '../../features/shared/settings/presentation/screens/settings_screen.dart';
import '../providers/navigation_provider.dart';
import '../services/fcm_service.dart';
import '../theme/app_colors.dart';

class MainLayout extends ConsumerStatefulWidget {
  final String userType;
  const MainLayout({super.key, required this.userType});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    FcmService.initialize();
    FcmService.setupForegroundHandler();
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
    // ignore: unused_local_variable
    final currentLocale = context.locale;
    final currentIndex = ref.watch(navigationIndexProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'home'.tr(),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.local_hospital_rounded,
                  label: 'centers'.tr(),
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.emoji_events_rounded,
                  label: 'legends'.tr(),
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.settings_rounded,
                  label: 'settings'.tr(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isSelected = currentIndex == index;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        ref.read(navigationIndexProvider.notifier).state = index;
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppColors.accent
                  : colors.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.accent
                    : colors.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
