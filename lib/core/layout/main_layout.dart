// file: lib/core/layout/main_layout.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/donor/dashboard/presentation/screens/donor_dashboard_screen.dart';
import '../../features/donor/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/receiver/map_finder/presentation/screens/receiver_map_screen.dart';
import '../../features/shared/ai_chat/presentation/screens/blood_ai_chat_screen.dart';
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
      const BloodAiChatScreen(),
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
              color: Colors.black.withValues(alpha: 0.05),
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
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'home'.tr(),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: Icons.local_hospital_rounded,
                    label: 'centers'.tr(),
                  ),
                ),
                Expanded(child: _buildAiNavItem()),
                Expanded(
                  child: _buildNavItem(
                    index: 3,
                    icon: Icons.emoji_events_rounded,
                    label: 'legends'.tr(),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 4,
                    icon: Icons.settings_rounded,
                    label: 'settings'.tr(),
                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
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
                  : colors.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.accent
                    : colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiNavItem() {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isSelected = currentIndex == 2;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        ref.read(navigationIndexProvider.notifier).state = 2;
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentDark, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent
                      .withValues(alpha: isSelected ? 0.34 : 0.22),
                  blurRadius: isSelected ? 18 : 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'ai_chat_tab'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? AppColors.accent
                  : colors.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
