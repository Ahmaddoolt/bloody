import 'package:bloody/core/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Compact eligibility timer row for settings
/// Matches the style of other toggle rows
class EligibilityTimer extends StatelessWidget {
  final bool isEligible;
  final String remainingTime;
  final double progress;

  const EligibilityTimer({
    super.key,
    required this.isEligible,
    required this.remainingTime,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      child: isEligible ? _buildEligibleView(colors) : _buildTimerView(colors),
    );
  }

  Widget _buildEligibleView(ColorScheme colors) {
    return Row(
      children: [
        // Icon - Green for eligible
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.check_circle,
            color: Color(0xFF4CAF50),
            size: 20,
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
                'ready_to_donate'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'eligibility_status'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerView(ColorScheme colors) {
    return Row(
      children: [
        // Icon - Blue for timer
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.timer_outlined,
            color: Color(0xFF1976D2),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'eligibility_status'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    remainingTime.isNotEmpty ? remainingTime : '--:--:--',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colors.outline.withOpacity(0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
