// file: lib/features/leaderboard/screens/leaderboard_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_loader.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
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
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('user_type', 'donor')
          .order('points', ascending: false)
          .range(_offset, _offset + _limit - 1);

      if (mounted) {
        if (data.length < _limit) _hasMore = false;

        setState(() {
          _leaders.addAll(List<Map<String, dynamic>>.from(data));
          _offset += _limit;
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
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
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _showDonorDetails(Map<String, dynamic> donor) {
    final String email = donor['email'] ?? 'unknown'.tr();
    final String name = email.split('@')[0];
    final String bloodType = donor['blood_type'] ?? '?';
    final String? phone = donor['phone'];
    // FIX: Ensure points are read correctly as an integer
    final int points = (donor['points'] as num? ?? 0).toInt();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color modalBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: modalBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryRed, width: 2),
              ),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: AppTheme.primaryRed,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      bloodType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gold.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: AppTheme.gold, size: 20),
                  const SizedBox(width: 6),
                  // FIX: Using the correct points variable directly
                  Text(
                    "$points ${'points'.tr()}",
                    style: const TextStyle(
                        color: AppTheme.gold, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                          color:
                              isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text("close".tr(),
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: phone != null ? () => _makeCall(phone) : null,
                    icon: const Icon(Icons.phone),
                    label: Text(
                      phone != null
                          ? "call_donor".tr()
                          : "no_phone_available".tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
      body: _isInitialLoading
          ? const CustomLoader()
          : _leaders.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: () async => await _fetchLeaders(loadMore: false),
                  color: AppTheme.primaryRed,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      _buildAppBar(isDark),
                      _buildPodiumSection(isDark),
                      _buildRestList(isDark),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return RefreshIndicator(
      onRefresh: () async => await _fetchLeaders(loadMore: false),
      color: AppTheme.primaryRed,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 80,
                        color: isDark ? Colors.grey[700] : Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text("no_legends".tr(),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.grey[500] : Colors.grey[600])),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 80,
      backgroundColor: AppTheme.darkRed,
      elevation: 0,
      title: Text(
        'legend_donors'.tr(),
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryRed, AppTheme.darkRed],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumSection(bool isDark) {
    if (_leaders.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    final top1 = _leaders.isNotEmpty ? _leaders[0] : null;
    final top2 = _leaders.length > 1 ? _leaders[1] : null;
    final top3 = _leaders.length > 2 ? _leaders[2] : null;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.darkRed, AppTheme.primaryRed],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        padding: const EdgeInsets.only(bottom: 50, top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (top2 != null)
              Expanded(
                  child: _buildPodiumWinner(
                      top2, 2, const Color(0xFFC0C0C0), isDark)),
            if (top1 != null)
              Expanded(
                flex: 1,
                child: Transform.translate(
                  offset: const Offset(0, -25),
                  child: _buildPodiumWinner(
                      top1, 1, const Color(0xFFFFD700), isDark),
                ),
              ),
            if (top3 != null)
              Expanded(
                  child: _buildPodiumWinner(
                      top3, 3, const Color(0xFFCD7F32), isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumWinner(
      Map<String, dynamic> donor, int rank, Color color, bool isDark) {
    final String email = donor['email'] ?? 'unknown';
    final String name = email.split('@')[0];
    final String bloodType = donor['blood_type'] ?? '?';
    final int points = (donor['points'] as num? ?? 0).toInt();

    final double avatarSize = rank == 1 ? 55 : 40;
    final double crownSize = rank == 1 ? 28 : 0;
    final Color textColor = Colors.white.withOpacity(0.95);

    return GestureDetector(
      onTap: () => _showDonorDetails(donor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank == 1)
            Icon(Icons.workspace_premium, color: color, size: crownSize),
          if (rank == 1) const SizedBox(height: 4),
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: CircleAvatar(
                  radius: avatarSize,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        bloodType,
                        style: TextStyle(
                          color: AppTheme.darkRed,
                          fontWeight: FontWeight.w900,
                          fontSize: rank == 1 ? 28 : 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.darkRed, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ]),
                  alignment: Alignment.center,
                  child: Text(
                    "$rank",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 16 : 14,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$points pts",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestList(bool isDark) {
    if (_leaders.length <= 3) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final realIndex = index + 3;
          if (realIndex >= _leaders.length) return null;

          final donor = _leaders[realIndex];
          return _buildListItem(donor, realIndex, isDark);
        },
        childCount: _leaders.length - 3 + (_hasMore ? 1 : 0),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> donor, int index, bool isDark) {
    if (index >= _leaders.length) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: CustomLoader(size: 30),
      );
    }

    final String email = donor['email'] ?? 'unknown';
    final String name = email.split('@')[0];
    final String bloodType = donor['blood_type'] ?? '?';
    final int points = (donor['points'] as num? ?? 0).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () => _showDonorDetails(donor),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 25,
              child: Text(
                "${index + 1}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: isDark
                  ? Colors.grey.shade800
                  : AppTheme.primaryRed.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: FittedBox(
                  child: Text(
                    bloodType,
                    style: const TextStyle(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 4),
              Text(
                "$points",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
