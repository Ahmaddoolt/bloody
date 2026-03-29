import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// Enhanced podium section with clean minimalist design
/// Shows top 3 donors in a beautiful podium layout
class PodiumSection extends StatelessWidget {
  final List<Map<String, dynamic>> leaders;
  final void Function(Map<String, dynamic> donor, int rank) onTap;

  const PodiumSection({
    super.key,
    required this.leaders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (leaders.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final top1 = leaders[0];
    final top2 = leaders.length > 1 ? leaders[1] : null;
    final top3 = leaders.length > 2 ? leaders[2] : null;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            _SectionLabel(colorScheme: colorScheme),
            const SizedBox(height: 20),
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
                      onTap: () => onTap(top2, 2),
                    ),
                  ),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: _PodiumCard(
                      donor: top1,
                      rank: 1,
                      rankColor: AppTheme.gold,
                      onTap: () => onTap(top1, 1),
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
                      onTap: () => onTap(top3, 3),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final ColorScheme colorScheme;
  const _SectionLabel({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(0.5),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'top_donors'.tr(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 24,
          height: 2,
          decoration: BoxDecoration(
            color: AppTheme.gold.withOpacity(0.5),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final Map<String, dynamic> donor;
  final int rank;
  final Color rankColor;
  final bool isWinner;
  final VoidCallback onTap;

  const _PodiumCard({
    required this.donor,
    required this.rank,
    required this.rankColor,
    required this.onTap,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rawName = donor['username'] ?? donor['email'];
    final name = (rawName != null && !rawName.toString().toLowerCase().contains('unknown'))
        ? (rawName as String).split('@')[0]
        : 'donor'.tr();
    final bloodType = donor['blood_type'] ?? '?';
    final points = (donor['points'] as num? ?? 0).toInt();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown for winner
          if (isWinner)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: rankColor,
                size: 22,
              ),
            ),
          // Avatar with blood type
          Container(
            width: isWinner ? 50 : 38,
            height: isWinner ? 50 : 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rankColor,
                  rankColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withOpacity(0.3),
                  blurRadius: isWinner ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                bloodType,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: isWinner ? 15 : 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: isWinner ? 13 : 11,
            ),
          ),
          const SizedBox(height: 4),
          // Points badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF2E7D32)),
                Text(
                  '$points',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Podium step
          Container(
            height: rank == 1
                ? 40
                : rank == 2
                    ? 28
                    : 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rankColor.withOpacity(0.15),
                  rankColor.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              border: Border(
                top: BorderSide(color: rankColor.withOpacity(0.4)),
                left: BorderSide(color: rankColor.withOpacity(0.4)),
                right: BorderSide(color: rankColor.withOpacity(0.4)),
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.w800,
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
