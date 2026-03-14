import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';

/// Deferral view showing countdown timer after donation
/// Follows clean minimalist UI principles:
/// - 8px grid spacing system
/// - Max 3 font sizes per section
/// - Consistent 16px card padding
/// - Generous whitespace for premium feel
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

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              _buildHeader(colors),
              const SizedBox(height: 16),
              // Timer Section
              _buildTimerSection(colors),
              const SizedBox(height: 16),
              // Info Card
              _buildInfoCard(colors),
              const SizedBox(height: 12),
              // Health Tip Card
              _buildHealthTipCard(colors),
              // Bottom whitespace is OK (25%)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent,
            AppColors.accent.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'thank_you_donor'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'donation_deferral_notice'.tr(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'time_until_next_donation'.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurface.withOpacity(0.6),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          // Progress Ring - Medium size
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withOpacity(0.05),
                  ),
                ),
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: AppColors.accent.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'recovered'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Time Display
          if (remainingTime.isEmpty)
            const AppLoadingIndicator(size: 24)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildTimeBoxes(remainingTime, colors),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeBoxes(String timeString, ColorScheme colors) {
    final parts = timeString.split('  ').where((s) => s.isNotEmpty).toList();
    final widgets = <Widget>[];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final number = part.replaceAll(RegExp(r'[^0-9]'), '');
      final unit = part.replaceAll(RegExp(r'[0-9]'), '');

      widgets.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                number,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildInfoCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'why_wait'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'deferral_explanation'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: colors.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.tips_and_updates_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'recovery_tip_title'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'recovery_tip_body'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: colors.onSurface.withOpacity(0.6),
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
