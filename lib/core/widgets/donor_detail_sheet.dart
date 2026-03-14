import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Reusable donor detail bottom sheet widget
/// Shows donor information with call action
/// Used in: Leaderboard, Search results, etc.
class DonorDetailSheet extends StatelessWidget {
  final Map<String, dynamic> donor;
  final int rank;
  final VoidCallback? onCall;

  const DonorDetailSheet({
    super.key,
    required this.donor,
    required this.rank,
    this.onCall,
  });

  Color get _rankColor => switch (rank) {
        1 => const Color(0xFFFFD700), // Gold
        2 => const Color(0xFFC0C0C0), // Silver
        3 => const Color(0xFFCD7F32), // Bronze
        _ => AppColors.accent,
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rawName = donor['username'] ?? donor['email'];
    final name = (rawName != null &&
            !rawName.toString().toLowerCase().contains('unknown'))
        ? (rawName as String).split('@')[0]
        : 'donor'.tr();
    final bloodType = donor['blood_type'] ?? '?';
    final phone = donor['phone'] as String?;
    final points = (donor['points'] as num? ?? 0).toInt();
    final city = donor['city'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Avatar with rank badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _rankColor,
                      _rankColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _rankColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
              if (rank <= 3)
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _rankColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _rankColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            name,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 4),

          // City if available
          if (city != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: colors.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr(city),
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Points badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: AppColors.accent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$points ${'points'.tr()}',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text('close'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurface.withOpacity(0.7),
                      side: BorderSide(color: colors.outline.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (phone != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: Text('call'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Helper function to show the donor detail sheet
void showDonorDetailSheet(
  BuildContext context, {
  required Map<String, dynamic> donor,
  required int rank,
  VoidCallback? onCall,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DonorDetailSheet(
      donor: donor,
      rank: rank,
      onCall: onCall,
    ),
  );
}
