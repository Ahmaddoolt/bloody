import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/custom_loader.dart';

class DeferralView extends StatelessWidget {
  final double progress;
  final String remainingTime;
  final Animation<double> ringAnimation;

  const DeferralView({
    super.key,
    required this.progress,
    required this.remainingTime,
    required this.ringAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Gradient header strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accentDark, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Text(
              'thank_you_donor'.tr(),
              style: AppTypography.displayMedium.copyWith(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _ProgressCard(
                  progress: progress,
                  remainingTime: remainingTime,
                  ringAnimation: ringAnimation,
                  colors: colors,
                ),
                SizedBox(height: AppSpacing.lg),
                _HealthTipCard(colors: colors),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double progress;
  final String remainingTime;
  final Animation<double> ringAnimation;
  final ColorScheme colors;

  const _ProgressCard({
    required this.progress,
    required this.remainingTime,
    required this.ringAnimation,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = Color.lerp(
      const Color(0xFFE65100),
      const Color(0xFF2E7D32),
      progress,
    ) ?? AppColors.accent;

    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular progress
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: ringAnimation,
                  builder: (_, __) => SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor:
                          const Color(0xFFE65100).withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(progressColor),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'recovered'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'donation_deferral_notice'.tr(),
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
              height: 1.6,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          // Countdown box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE65100).withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'time_until_next_donation'.tr(),
                  style: AppTypography.label.copyWith(
                    fontSize: 12,
                    color: colors.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                remainingTime.isEmpty
                    ? const CustomLoader(size: 24)
                    : Text(
                        remainingTime,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: colors.onSurface,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthTipCard extends StatelessWidget {
  final ColorScheme colors;
  const _HealthTipCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.blue.shade700.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.shade700.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.shade700.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tips_and_updates_rounded,
              color: Colors.blue.shade700,
              size: 22,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'recovery_tip_title'.tr(),
                  style: AppTypography.label.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'recovery_tip_body'.tr(),
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    height: 1.6,
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
