import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_typography.dart';

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

    final colors = Theme.of(context).colorScheme;
    final top1 = leaders[0];
    final top2 = leaders.length > 1 ? leaders[1] : null;
    final top3 = leaders.length > 2 ? leaders[2] : null;

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            _SectionLabel(colors: colors),
            SizedBox(height: AppSpacing.lg),
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
                    offset: const Offset(0, -20),
                    child: _PodiumCard(
                      donor: top1,
                      rank: 1,
                      rankColor: const Color(0xFFFFD700),
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
  final ColorScheme colors;
  const _SectionLabel({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 2,
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          'top_donors'.tr(),
          style: AppTypography.label.copyWith(
            fontSize: 12,
            letterSpacing: 1.5,
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Container(
          width: 28,
          height: 2,
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.5),
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
    final colors = Theme.of(context).colorScheme;
    final name = ((donor['email'] ?? 'unknown') as String).split('@')[0];
    final bloodType = donor['blood_type'] ?? '?';
    final points = (donor['points'] as num? ?? 0).toInt();

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
              color: rankColor.withValues(alpha: 0.15),
              border: Border.all(
                color: rankColor.withValues(alpha: 0.6),
                width: isWinner ? 2.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.3),
                  blurRadius: isWinner ? 14 : 8,
                  offset: const Offset(0, 4),
                ),
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
          SizedBox(height: AppSpacing.sm),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: isWinner ? 13 : 11,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: rankColor.withValues(alpha: 0.35)),
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
          SizedBox(height: AppSpacing.sm),
          // Podium step
          Container(
            height: rank == 1 ? 48 : rank == 2 ? 36 : 24,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              border: Border(
                top: BorderSide(color: rankColor.withValues(alpha: 0.4)),
                left: BorderSide(color: rankColor.withValues(alpha: 0.4)),
                right: BorderSide(color: rankColor.withValues(alpha: 0.4)),
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
