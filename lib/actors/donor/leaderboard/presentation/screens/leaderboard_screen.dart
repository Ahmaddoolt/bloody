// file: lib/actors/donor/leaderboard/presentation/screens/leaderboard_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_loader.dart';
import '../../data/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _service = LeaderboardService();

  final List<Map<String, dynamic>> _leaders = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _limit = 20;
  int _offset = 0;

  final ScrollController _scrollController = ScrollController();

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
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
      if (mounted)
        setState(() {
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
    }
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _showDonorDetails(Map<String, dynamic> donor, int rank) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String email = donor['email'] ?? 'unknown';
    final String name = email.split('@')[0];
    final String bloodType = donor['blood_type'] ?? '?';
    final String? phone = donor['phone'];
    final int points = (donor['points'] as num? ?? 0).toInt();

    final Color rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : AppTheme.primaryRed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.35), borderRadius: BorderRadius.circular(2))),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [rankColor, rankColor.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: rankColor.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Center(
                    child: Text(bloodType,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  ),
                ),
                if (rank <= 3)
                  Positioned(
                    bottom: -6,
                    right: -6,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppTheme.darkCard : Colors.white,
                          border: Border.all(color: rankColor, width: 1.5)),
                      child: Center(
                          child: Text('#$rank',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold, color: rankColor))),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(name,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.bolt_rounded, color: AppTheme.gold, size: 18),
                const SizedBox(width: 6),
                Text('$points ${'points'.tr()}',
                    style: const TextStyle(
                        color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
            ),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text('close'.tr(),
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: phone != null ? () => _makeCall(phone) : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: Text(
                    phone != null ? 'call_donor'.tr() : 'no_phone_available'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF5F6FA),
      appBar: _buildAppBar(isDark),
      body: _isInitialLoading
          ? const CustomLoader()
          : _leaders.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: () async => _fetchLeaders(loadMore: false),
                  color: AppTheme.gold,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      _buildPodiumSection(isDark),
                      _buildRankList(isDark),
                      if (_hasMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CustomLoader(size: 28),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryRed,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, color: AppTheme.gold, size: 22),
          const SizedBox(width: 8),
          Text(
            'legend_donors'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 40, color: AppTheme.gold),
          ),
          const SizedBox(height: 20),
          Text("no_legends".tr(),
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
  }

  // ─── Podium Section ────────────────────────────────────────────────────────

  Widget _buildPodiumSection(bool isDark) {
    if (_leaders.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    final top1 = _leaders[0];
    final top2 = _leaders.length > 1 ? _leaders[1] : null;
    final top3 = _leaders.length > 2 ? _leaders[2] : null;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        decoration: BoxDecoration(
          // Subtle card background — no giant gradient
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRed.withOpacity(isDark ? 0.15 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Section label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'top_donors'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 28,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Podium row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (top2 != null)
                  Expanded(
                      child: _PodiumCard(
                    donor: top2,
                    rank: 2,
                    rankColor: const Color(0xFFC0C0C0),
                    isDark: isDark,
                    onTap: () => _showDonorDetails(top2, 2),
                  )),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: _PodiumCard(
                      donor: top1,
                      rank: 1,
                      rankColor: const Color(0xFFFFD700),
                      isDark: isDark,
                      onTap: () => _showDonorDetails(top1, 1),
                      isWinner: true,
                    ),
                  ),
                ),
                if (top3 != null)
                  Expanded(
                      child: _PodiumCard(
                    donor: top3,
                    rank: 3,
                    rankColor: const Color(0xFFCD7F32),
                    isDark: isDark,
                    onTap: () => _showDonorDetails(top3, 3),
                  )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Rank List ─────────────────────────────────────────────────────────────

  Widget _buildRankList(bool isDark) {
    if (_leaders.length <= 3) return const SliverToBoxAdapter(child: SizedBox());

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, index) {
            final realIndex = index + 3;
            if (realIndex >= _leaders.length) return null;
            return _RankListItem(
              donor: _leaders[realIndex],
              rank: realIndex + 1,
              isDark: isDark,
              onTap: () => _showDonorDetails(_leaders[realIndex], realIndex + 1),
            );
          },
          childCount: _leaders.length - 3,
        ),
      ),
    );
  }
}

// ── Podium card widget ────────────────────────────────────────────────────────

class _PodiumCard extends StatelessWidget {
  final Map<String, dynamic> donor;
  final int rank;
  final Color rankColor;
  final bool isDark;
  final bool isWinner;
  final VoidCallback onTap;

  const _PodiumCard({
    required this.donor,
    required this.rank,
    required this.rankColor,
    required this.isDark,
    required this.onTap,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    final String email = donor['email'] ?? 'unknown';
    final String name = email.split('@')[0];
    final String bloodType = donor['blood_type'] ?? '?';
    final int points = (donor['points'] as num? ?? 0).toInt();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWinner)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Icon(Icons.workspace_premium_rounded, color: rankColor, size: 26),
            ),
          // Avatar
          Container(
            width: isWinner ? 66 : 52,
            height: isWinner ? 66 : 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withOpacity(0.15),
              border: Border.all(color: rankColor.withOpacity(0.6), width: isWinner ? 2.5 : 2),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withOpacity(0.3),
                  blurRadius: isWinner ? 14 : 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Center(
              child: Text(
                bloodType,
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isWinner ? 20 : 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: isWinner ? 13 : 11,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: rankColor.withOpacity(0.35), width: 1),
            ),
            child: Text(
              '$points pts',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Podium step block
          Container(
            height: rank == 1
                ? 48
                : rank == 2
                    ? 36
                    : 24,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              border: Border(
                top: BorderSide(color: rankColor.withOpacity(0.4), width: 1),
                left: BorderSide(color: rankColor.withOpacity(0.4), width: 1),
                right: BorderSide(color: rankColor.withOpacity(0.4), width: 1),
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rank list item ────────────────────────────────────────────────────────────

class _RankListItem extends StatelessWidget {
  final Map<String, dynamic> donor;
  final int rank;
  final bool isDark;
  final VoidCallback onTap;

  const _RankListItem({
    required this.donor,
    required this.rank,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String name = (donor['email'] ?? 'unknown').split('@')[0];
    final String bloodType = donor['blood_type'] ?? '?';
    final int points = (donor['points'] as num? ?? 0).toInt();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  bloodType,
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gold.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: AppTheme.gold, size: 13),
                  const SizedBox(width: 3),
                  Text('$points',
                      style: const TextStyle(
                          color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
