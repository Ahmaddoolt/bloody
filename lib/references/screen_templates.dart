// file: lib/references/screen_templates.dart
//
// Screen Templates — Reference Patterns
//
// Structural blueprints for common screen types. Adapt the layout, spacing,
// and components to each specific use case.
//
// Patterns included:
//  • OnboardingScreen  — PageView + dot indicator + bottom CTA
//  • ProfileScreen     — SliverAppBar collapsing header + stats row
//  • SettingsScreen    — Grouped rows with toggle and navigation items
//  • DashboardScreen   — KPI cards + chart area + activity list
//
// NOTE: Providers, navigation calls, and data models are stubs.
//       Replace them with your actual data layer.
//
// ignore_for_file: unused_element, deprecated_member_use

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'button_patterns.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Stub data models
// ═════════════════════════════════════════════════════════════════════════════

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final String asset;
  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.asset,
  });
}

class _UserProfile {
  final String name;
  final String bio;
  final String avatarUrl;
  final int postCount;
  final int followerCount;
  final int followingCount;
  const _UserProfile({
    required this.name,
    required this.bio,
    required this.avatarUrl,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. Onboarding Screen
// ═════════════════════════════════════════════════════════════════════════════
//
// Key design decisions:
// - Full-bleed gradient or illustration background
// - PageView with physics: BouncingScrollPhysics()
// - Custom dot indicator (animated width change, not just color)
// - Bottom CTA area pinned outside the PageView
// - Staggered entrance animation on each page change

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPageData(
      title: 'Welcome',
      subtitle: 'Discover a new way to manage your day',
      asset: 'assets/onboarding_1.svg',
    ),
    _OnboardingPageData(
      title: 'Track Progress',
      subtitle: 'Stay on top of every task with clear insights',
      asset: 'assets/onboarding_2.svg',
    ),
    _OnboardingPageData(
      title: 'Get Started',
      subtitle: 'Join thousands of people achieving more',
      asset: 'assets/onboarding_3.svg',
    ),
  ];

  void _navigateToHome() {
    // TODO: Replace with your actual navigation
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button — top right, ghost style
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: AppButton(
                  label: 'Skip',
                  variant: AppButtonVariant.ghost,
                  isExpanded: false,
                  onPressed: _navigateToHome,
                ),
              ),
            ),

            // Page content — takes remaining space
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // TODO: Replace with your actual asset / illustration
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 80,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: AppTypography.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dot indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _DotIndicator(
                count: _pages.length,
                current: _currentPage,
              ),
            ),

            // CTA button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: AppButton(
                label:
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                onPressed: () {
                  if (_currentPage == _pages.length - 1) {
                    _navigateToHome();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated dot indicator — active dot stretches wider
class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accent
                : AppColors.textTertiary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 2. Profile Screen
// ═════════════════════════════════════════════════════════════════════════════
//
// Key design decisions:
// - Scrollable with SliverAppBar for collapsing header
// - Avatar with subtle shadow ring, not a flat circle
// - Stats row with dividers (followers, posts, etc.)
// - Content sections with clear visual separation
// - Edit button floats or pins contextually

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // TODO: Replace with your actual data source
  static const _profile = _UserProfile(
    name: 'John Doe',
    bio: 'Flutter developer & coffee enthusiast.',
    avatarUrl: 'https://i.pravatar.cc/150',
    postCount: 42,
    followerCount: 1200,
    followingCount: 340,
  );

  void _showOptions(BuildContext context) {
    // TODO: Show options bottom sheet
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsing header with gradient background
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(profile: _profile),
            ),
            leading: AppIconButton(
              icon: Icons.arrow_back_ios_new,
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              AppIconButton(
                icon: Icons.more_horiz,
                onPressed: () => _showOptions(context),
              ),
            ],
          ),

          // Stats row
          SliverToBoxAdapter(
            child: _StatsRow(
              stats: [
                _Stat('Posts', _profile.postCount),
                _Stat('Followers', _profile.followerCount),
                _Stat('Following', _profile.followingCount),
              ],
            ),
          ),

          // Content section
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text('Recent Activity', style: AppTypography.titleLarge),
                  const SizedBox(height: 16),
                  // TODO: Insert your actual content list here
                  const Text('Content goes here…'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final _UserProfile profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.1),
            AppColors.background,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Avatar with ring shadow
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundImage: NetworkImage(profile.avatarUrl),
              ),
            ),
            const SizedBox(height: 16),
            Text(profile.name, style: AppTypography.displayMedium),
            const SizedBox(height: 4),
            Text(
              profile.bio,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal stats row with formatted counters
class _StatsRow extends StatelessWidget {
  final List<_Stat> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: stats.asMap().entries.map((entry) {
          final isLast = entry.key == stats.length - 1;
          return Expanded(
            child: Container(
              decoration: isLast
                  ? null
                  : BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: AppColors.surfaceVariant,
                          width: 1,
                        ),
                      ),
                    ),
              child: Column(
                children: [
                  Text(
                    _formatCount(entry.value.value),
                    style: AppTypography.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.value.label,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _Stat {
  final String label;
  final int value;
  const _Stat(this.label, this.value);
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. Settings Screen
// ═════════════════════════════════════════════════════════════════════════════
//
// Key design decisions:
// - Grouped sections with subtle header labels
// - Toggle rows with animated switch
// - Navigation rows with chevron
// - Danger zone section at bottom (red accent)
// - No Material ListTile — custom rows for visual control

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // TODO: Replace with your actual state management
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      title: const Text('Settings'),
      leading: AppIconButton(
        icon: Icons.arrow_back_ios_new,
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    // TODO: Show confirmation dialog and handle logout
  }

  void _confirmDelete(BuildContext context) {
    // TODO: Show confirmation dialog and handle account deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader('Preferences'),
            _SettingsGroup(children: [
              _ToggleRow(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                value: _isDarkMode,
                onChanged: (v) => setState(() => _isDarkMode = v),
              ),
              _ToggleRow(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
            ]),
            const SizedBox(height: 32),
            _SectionHeader('Account'),
            _SettingsGroup(children: [
              _NavigationRow(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                onTap: () => Navigator.of(context).pushNamed('/profile/edit'),
              ),
              _NavigationRow(
                icon: Icons.lock_outline,
                label: 'Privacy',
                onTap: () =>
                    Navigator.of(context).pushNamed('/settings/privacy'),
              ),
            ]),
            const SizedBox(height: 32),
            _SectionHeader('Danger Zone'),
            _SettingsGroup(
              isDanger: true,
              children: [
                _NavigationRow(
                  icon: Icons.logout,
                  label: 'Log Out',
                  isDanger: true,
                  onTap: () => _confirmLogout(context),
                ),
                _NavigationRow(
                  icon: Icons.delete_forever_outlined,
                  label: 'Delete Account',
                  isDanger: true,
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDanger;
  const _SettingsGroup({required this.children, this.isDanger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDanger
            ? Border.all(color: Colors.red.withOpacity(0.15))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 52,
                  color: AppColors.surfaceVariant,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.label.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          Switch(
            value: value,
            activeColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NavigationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _NavigationRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.red : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(color: color),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 4. Dashboard Screen
// ═════════════════════════════════════════════════════════════════════════════
//
// Key design decisions:
// - Greeting + date at top (personalized)
// - KPI cards in a horizontal scroll or 2×2 grid
// - Main chart area with period selector
// - Recent activity list below
// - Pull-to-refresh on the whole scroll
//
// Use GlassContainer (see glass_container.dart) for KPI cards when the
// dashboard has a gradient or image background.
// Use regular elevated cards (subtle shadow, white fill) for flat backgrounds.

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  const _KpiData(this.label, this.value, this.icon);
}

class _ActivityData {
  final String title;
  final String time;
  const _ActivityData(this.title, this.time);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // TODO: Replace with actual data from your data layer
  final List<_KpiData> kpis = const [
    _KpiData('Revenue', '\$12.4K', Icons.trending_up),
    _KpiData('Users', '3,291', Icons.people_outline),
    _KpiData('Orders', '148', Icons.receipt_outlined),
    _KpiData('Returns', '3.2%', Icons.undo_outlined),
  ];

  final List<_ActivityData> activities = const [
    _ActivityData('New user registered', '2 min ago'),
    _ActivityData('Order #1042 completed', '15 min ago'),
    _ActivityData('Payment received', '1 hr ago'),
  ];

  Future<void> _onRefresh() async {
    // TODO: Re-fetch dashboard data
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              // Greeting header (not an AppBar)
              SliverToBoxAdapter(child: _GreetingHeader()),

              // KPI cards — horizontal scroll
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: kpis.length,
                    itemBuilder: (_, i) => _KpiCard(kpi: kpis[i]),
                  ),
                ),
              ),

              // Chart section placeholder
              SliverToBoxAdapter(child: _ChartSection()),

              // Recent activity
              SliverPadding(
                padding: AppSpacing.page,
                sliver: SliverList.separated(
                  itemCount: activities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _ActivityRow(activity: activities[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Padding(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: AppTypography.titleLarge),
          const SizedBox(height: 4),
          Text(
            // TODO: Insert actual user name
            'Welcome back!',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _KpiData kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(kpi.icon, color: AppColors.accent, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kpi.value, style: AppTypography.titleLarge),
              const SizedBox(height: 2),
              Text(
                kpi.label,
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'Chart goes here',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _ActivityData activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(activity.title, style: AppTypography.bodyMedium),
          ),
          Text(
            activity.time,
            style: AppTypography.label.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}