// file: lib/shared/settings/presentation/screens/donation_history_screen.dart
import 'package:bloody/core/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../data/settings_service.dart';

class DonationHistoryScreen extends ConsumerStatefulWidget {
  final String userId;
  const DonationHistoryScreen({super.key, required this.userId});

  @override
  ConsumerState<DonationHistoryScreen> createState() =>
      _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends ConsumerState<DonationHistoryScreen> {
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
    if (mounted) {
      setState(() {
        _history = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator())
          : _history.isEmpty
              ? _buildEmptyState(colors)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) =>
                        _buildHistoryItem(_history[i], i, colors),
                  ),
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('donation_history'.tr()),
      centerTitle: true,
      actions: [
        if (!_isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volunteer_activism,
                      color: Theme.of(context).colorScheme.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${_history.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 40,
              color: colors.onSurface.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'no_donations_yet'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'your_donations_appear_here'.tr(),
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    Map<String, dynamic> donation,
    int index,
    ColorScheme colors,
  ) {
    final String rawDate = donation['created_at'] ?? '';
    final String date = rawDate.isNotEmpty
        ? DateFormat.yMd(context.locale.languageCode)
            .format(DateTime.parse(rawDate).toLocal())
        : 'n_a'.tr();
    final String center = donation['centers']?['name'] ?? 'unknown_center'.tr();
    final String status = donation['status'] ?? 'completed';
    final bool isCompleted = status == 'completed';

    final Color statusColor = isCompleted
        ? const Color(0xFF4CAF50) // Green for completed
        : const Color(0xFF1976D2); // Blue for pending

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: colors.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.hourglass_top,
                    size: 12,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isCompleted ? 'completed'.tr() : 'pending'.tr(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
