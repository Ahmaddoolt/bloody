import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Compact rank list item - NOT tappable
/// Shows rank, blood type, name, city, points, and call button
/// Clean, minimalist, ~72px height
class RankListItem extends StatelessWidget {
  final Map<String, dynamic> donor;
  final int rank;
  final VoidCallback? onCall;

  const RankListItem({
    super.key,
    required this.donor,
    required this.rank,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rawName = donor['username'] ?? donor['email'];
    final name = (rawName != null &&
            !rawName.toString().toLowerCase().contains('unknown'))
        ? (rawName as String).split('@')[0]
        : 'donor'.tr();
    final bloodType = donor['blood_type'] ?? '?';
    final points = (donor['points'] as num? ?? 0).toInt();
    final city = donor['city'] as String?;
    final phone = donor['phone'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            // Rank number
            SizedBox(
              width: 32,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface.withOpacity(0.4),
                ),
              ),
            ),
            // Blood type badge (like CenterCard icon)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent,
                    AppColors.accent.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  bloodType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (city != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          context.tr(city),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Points badge (GREEN)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: const Color(0xFF2E7D32),
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$points',
                    style: TextStyle(
                      color: const Color(0xFF2E7D32),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Call button (RED - if phone available)
            if (phone != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onCall,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.phone_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
