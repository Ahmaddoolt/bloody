// file: lib/shared/settings/presentation/screens/donation_history_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/custom_loader.dart';
import '../../data/settings_service.dart';

class DonationHistoryScreen extends StatefulWidget {
  final String userId;
  const DonationHistoryScreen({super.key, required this.userId});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  final SettingsService _service = SettingsService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _service.getDonationHistory(widget.userId);
    if (mounted)
      setState(() {
        _history = data;
        _isLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF5F6FA),
      appBar: _buildAppBar(isDark),
      body: _isLoading
          ? const CustomLoader()
          : _history.isEmpty
              ? _buildEmpty(isDark)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryRed,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    itemCount: _history.length,
                    itemBuilder: (ctx, i) => _buildHistoryItem(_history[i], i, isDark),
                  ),
                ),
    );
  }

  // ── AppBar — same style as Settings & Leaderboard ──────────────

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryRed,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      title: Text(
        'donation_history'.tr(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      // Donations count badge on the right
      actions: [
        if (!_isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volunteer_activism, color: Colors.white, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      '${_history.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
    );
  }

  // ── History item ────────────────────────────────────────────────

  Widget _buildHistoryItem(Map<String, dynamic> donation, int index, bool isDark) {
    final String rawDate = donation['created_at'] ?? '';
    final String date =
        rawDate.isNotEmpty ? DateTime.parse(rawDate).toLocal().toString().split(' ')[0] : 'N/A';
    final String center = donation['centers']?['name'] ?? 'Unknown Center';
    final String status = donation['status'] ?? 'completed';
    final bool isCompleted = status == 'completed';

    final Color statusColor = isCompleted ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left accent strip
          Container(
            width: 56,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.volunteer_activism, color: AppTheme.primaryRed, size: 22),
                const SizedBox(height: 4),
                Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Status badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                    size: 11,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, size: 48, color: AppTheme.primaryRed),
          ),
          const SizedBox(height: 20),
          Text(
            'no_donations_yet'.tr(),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'your_donations_appear_here'.tr(),
            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
