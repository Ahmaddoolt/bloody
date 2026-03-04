import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/custom_loader.dart';
import '../../data/leaderboard_service.dart';
import '../widgets/donor_detail_sheet.dart';
import '../widgets/podium_section.dart';
import '../widgets/rank_list_item.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _service = LeaderboardService();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _leaders = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _limit = 20;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchLeaders();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _fetchLeaders(loadMore: true);
    }
  }

  Future<void> _fetchLeaders({bool loadMore = false}) async {
    if (loadMore && (_isLoadingMore || !_hasMore)) return;
    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        if (_leaders.isEmpty) _isInitialLoading = true;
        _offset = 0;
        _hasMore = true;
        _leaders.clear();
      }
    });
    try {
      final data = await _service.fetchTopDonors(offset: _offset, limit: _limit);
      if (mounted) {
        if (data.length < _limit) _hasMore = false;
        setState(() {
          _leaders.addAll(data);
          _offset += _limit;
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isInitialLoading
          ? const CustomLoader()
          : _leaders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async => _fetchLeaders(loadMore: false),
                  color: AppTheme.gold,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      PodiumSection(
                        leaders: _leaders,
                        onTap: (donor, rank) => showDonorDetailSheet(
                          context,
                          donor: donor,
                          rank: rank,
                          onCall: _makeCall,
                        ),
                      ),
                      _buildRankList(),
                      if (_hasMore)
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppTheme.gold, size: 22),
          SizedBox(width: AppSpacing.sm),
          Text(
            'legend_donors'.tr(),
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
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

  Widget _buildRankList() {
    if (_leaders.length <= 3) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, index) {
            final realIndex = index + 3;
            if (realIndex >= _leaders.length) return null;
            return RankListItem(
              donor: _leaders[realIndex],
              rank: realIndex + 1,
              onTap: () => showDonorDetailSheet(
                context,
                donor: _leaders[realIndex],
                rank: realIndex + 1,
                onCall: _makeCall,
              ),
            );
          },
          childCount: _leaders.length - 3,
        ),
      ),
    );
  }
}
