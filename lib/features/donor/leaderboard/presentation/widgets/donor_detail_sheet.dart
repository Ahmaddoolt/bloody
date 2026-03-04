import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_typography.dart';

void showDonorDetailSheet(
  BuildContext context, {
  required Map<String, dynamic> donor,
  required int rank,
  required void Function(String? phone) onCall,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DonorDetailSheet(
      donor: donor,
      rank: rank,
      onCall: onCall,
    ),
  );
}

class _DonorDetailSheet extends StatelessWidget {
  final Map<String, dynamic> donor;
  final int rank;
  final void Function(String? phone) onCall;

  const _DonorDetailSheet({
    required this.donor,
    required this.rank,
    required this.onCall,
  });

  Color get _rankColor => switch (rank) {
        1 => const Color(0xFFFFD700),
        2 => const Color(0xFFC0C0C0),
        3 => const Color(0xFFCD7F32),
        _ => AppTheme.primaryRed,
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = ((donor['email'] ?? 'unknown') as String).split('@')[0];
    final bloodType = donor['blood_type'] ?? '?';
    final phone = donor['phone'] as String?;
    final points = (donor['points'] as num? ?? 0).toInt();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Avatar with rank badge
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
                    colors: [_rankColor, _rankColor.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _rankColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    bloodType,
                    style: AppTypography.displayMedium.copyWith(
                      color: Colors.white,
                      fontSize: 26,
                    ),
                  ),
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
                      color: colors.surface,
                      border: Border.all(color: _rankColor, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _rankColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          // Name
          Text(
            name,
            style: AppTypography.displayMedium.copyWith(
              fontSize: 22,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          // Points badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: AppTheme.gold, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$points ${'points'.tr()}',
                  style: AppTypography.label.copyWith(
                    color: AppTheme.gold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  label: 'close'.tr(),
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Colors.transparent,
                  foregroundColor: colors.onSurface.withValues(alpha: 0.7),
                  borderColor: colors.outline,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SheetButton(
                  label: phone != null ? 'call_donor'.tr() : 'no_phone_available'.tr(),
                  icon: Icons.phone_rounded,
                  onPressed: phone != null ? () => onCall(phone) : null,
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  const _SheetButton({
    required this.label,
    this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final effectiveBg = isDisabled
        ? backgroundColor.withValues(alpha: 0.4)
        : backgroundColor;
    final effectiveFg = isDisabled
        ? foregroundColor.withValues(alpha: 0.5)
        : foregroundColor;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(14),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
          boxShadow: !isDisabled && backgroundColor != Colors.transparent
              ? [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: effectiveFg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(color: effectiveFg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
