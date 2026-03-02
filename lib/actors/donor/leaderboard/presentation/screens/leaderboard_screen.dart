// file: lib/actors/donor/features/leaderboard/presentation/screens/leaderboard_screen.dart
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
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  void _showDonorDetails(Map<String, dynamic> donor) {
    final String email = donor['email'] ?? 'unknown'.tr();
    final String name = email.split('@')[0];
    final String bloodType = donor['blood_type'] ?? '?';
    final String? phone = donor['phone'];
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
                    borderRadius: BorderRadius.circular(2))),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryRed, width: 2)),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: AppTheme.primaryRed,
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(
                        child: Text(bloodType,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)))),
              ),
            ),
            const SizedBox(height: 16),
            Text(name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.5))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.bolt, color: AppTheme.gold, size: 20),
                const SizedBox(width: 6),
                Text("$points ${'points'.tr()}",
                    style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))
              ]),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: Text("close".tr(),
                            style: TextStyle(color: isDark ? Colors.white : Colors.black)))),
                const SizedBox(width: 16),
                Expanded(
                    child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: phone != null ? () => _makeCall(phone) : null,
                        icon: const Icon(Icons.phone),
                        label: Text(phone != null ? "call_donor".tr() : "no_phone_available".tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold)))),
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
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA),
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
                      _buildRestList(isDark)
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
        child: Text("no_legends".tr(), style: TextStyle(fontSize: 18, color: Colors.grey)));
  }

  SliverAppBar _buildAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 80,
      backgroundColor: AppTheme.darkRed,
      elevation: 0,
      title: Text('legend_donors'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      centerTitle: true,
      flexibleSpace: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppTheme.primaryRed, AppTheme.darkRed],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter))),
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
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40))),
        padding: const EdgeInsets.only(bottom: 50, top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (top2 != null)
              Expanded(child: _buildPodiumWinner(top2, 2, const Color(0xFFC0C0C0), isDark)),
            if (top1 != null)
              Expanded(
                  flex: 1,
                  child: Transform.translate(
                      offset: const Offset(0, -25),
                      child: _buildPodiumWinner(top1, 1, const Color(0xFFFFD700), isDark))),
            if (top3 != null)
              Expanded(child: _buildPodiumWinner(top3, 3, const Color(0xFFCD7F32), isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumWinner(Map<String, dynamic> donor, int rank, Color color, bool isDark) {
    final String email = donor['email'] ?? 'unknown';
    final String name = email.split('@')[0];
    final String bloodType = donor['blood_type'] ?? '?';
    final int points = (donor['points'] as num? ?? 0).toInt();

    return GestureDetector(
      onTap: () => _showDonorDetails(donor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank == 1) Icon(Icons.workspace_premium, color: color, size: 28),
          CircleAvatar(
              radius: rank == 1 ? 30 : 25,
              backgroundColor: color,
              child: Text(bloodType,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          const SizedBox(height: 8),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text("$points pts",
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRestList(bool isDark) {
    if (_leaders.length <= 3) return const SliverToBoxAdapter(child: SizedBox());
    return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
      final realIndex = index + 3;
      if (realIndex >= _leaders.length) return null;
      return _buildListItem(_leaders[realIndex], realIndex, isDark);
    }, childCount: _leaders.length - 3 + (_hasMore ? 1 : 0)));
  }

  Widget _buildListItem(Map<String, dynamic> donor, int index, bool isDark) {
    final String name = (donor['email'] ?? 'unknown').split('@')[0];
    final String bloodType = donor['blood_type'] ?? '?';
    final int points = (donor['points'] as num? ?? 0).toInt();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: ListTile(
        onTap: () => _showDonorDetails(donor),
        leading: CircleAvatar(
            backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
            child: Text(bloodType,
                style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold))),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text("$points pts",
            style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
