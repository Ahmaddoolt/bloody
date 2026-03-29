import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/custom_loader.dart';
import '../../../../../core/widgets/info_bottom_sheet.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/podium_section.dart';
import '../widgets/rank_list_item.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardProvider.notifier).fetchDonors();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(leaderboardProvider);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!state.isLoadingMore && state.hasMore) {
        ref.read(leaderboardProvider.notifier).loadMore();
      }
    }
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  VoidCallback? _createCallCallback(String? phone) {
    if (phone == null || phone.isEmpty) return null;
    return () => _makeCall(phone);
  }

  void _showDonorBottomSheet(Map<String, dynamic> donor, int rank) {
    final rawName = donor['username'] ?? donor['email'];
    final name = (rawName != null && !rawName.toString().toLowerCase().contains('unknown'))
        ? (rawName as String).split('@')[0]
        : 'donor'.tr();
    final bloodType = donor['blood_type'] ?? '?';
    final phone = donor['phone'] as String?;
    final points = (donor['points'] as num? ?? 0).toInt();
    final city = donor['city'] as String?;

    showInfoBottomSheet(
      context,
      title: name,
      subtitle: '$bloodType ${'blood_type'.tr()}',
      avatar: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent,
              AppColors.accent.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            bloodType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      infoRows: [
        if (city != null)
          InfoRow(
            icon: Icons.location_on_outlined,
            text: context.tr(city),
          ),
        InfoRow(
          icon: Icons.bolt_rounded,
          text: '$points ${'points'.tr()}',
          color: const Color(0xFF2E7D32),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      ],
      actions: [
        SheetAction(
          label: 'close'.tr(),
          onPressed: () => Navigator.pop(context),
          isOutlined: true,
        ),
        if (phone != null)
          SheetAction(
            label: 'call'.tr(),
            icon: Icons.phone_rounded,
            onPressed: () {
              _makeCall(phone);
              Navigator.pop(context);
            },
            backgroundColor: AppColors.accent,
          ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);
    final currentUserRankAsync = ref.watch(currentUserRankProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(state, currentUserRankAsync, colorScheme),
      body: state.isLoading && state.donors.isEmpty
          ? const Center(child: AppLoadingIndicator())
          : state.donors.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async => ref.read(leaderboardProvider.notifier).refresh(),
                  color: AppTheme.gold,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      PodiumSection(
                        leaders: state.donors.map((d) => d.toJson()).toList(),
                        onTap: (donor, rank) => _showDonorBottomSheet(donor, rank),
                      ),
                      _buildRankList(state),
                      if (state.hasMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CustomLoader(size: 28),
                          ),
                        ),
                      SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
                    ],
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    LeaderboardState state,
    AsyncValue<int?> currentUserRankAsync,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 78,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentDark, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: AppTheme.gold,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'legend_donors'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Total donors badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${state.totalCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // User rank badge
                      currentUserRankAsync.when(
                        data: (rank) => rank != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.military_tech_rounded,
                                      color: AppTheme.gold,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$rank',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 40, color: AppTheme.gold),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'no_legends'.tr(),
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankList(LeaderboardState state) {
    if (state.donors.length <= 3) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, index) {
            final realIndex = index + 3;
            if (realIndex >= state.donors.length) return null;
            final donor = state.donors[realIndex];
            return RankListItem(
              donor: donor.toJson(),
              rank: realIndex + 1,
              onCall: _createCallCallback(donor.phone),
            );
          },
          childCount: state.donors.length - 3,
        ),
      ),
    );
  }
}
