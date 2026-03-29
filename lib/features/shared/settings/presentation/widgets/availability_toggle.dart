import 'package:bloody/core/widgets/app_loading_indicator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Compact availability toggle row for settings
/// Matches the style of other toggle rows
class AvailabilityToggle extends StatelessWidget {
  final bool isAvailable;
  final bool isLoading;
  final ValueChanged<bool> onChanged;

  const AvailabilityToggle({
    super.key,
    required this.isAvailable,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Green for availability (ready/online state)
    final iconColor = isAvailable
        ? const Color(0xFF4CAF50)
        : colors.onSurface.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Icon - Green for availability
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : colors.outline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isAvailable ? Icons.wifi_tethering : Icons.wifi_tethering_off,
              color: iconColor,
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
                  isAvailable
                      ? 'availability_online'.tr()
                      : 'availability_offline'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAvailable
                      ? 'availability_online_desc'.tr()
                      : 'availability_offline_desc'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const AppLoadingIndicator(
              size: 24,
              strokeWidth: 2,
            )
          else
            Switch(
              value: isAvailable,
              onChanged: onChanged,
              activeColor: const Color(0xFF4CAF50),
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: Colors.grey.shade300,
            ),
        ],
      ),
    );
  }
}
