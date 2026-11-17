import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LocationPickerRow extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final bool enabled;
  final VoidCallback? onTap;

  const LocationPickerRow({
    super.key,
    this.latitude,
    this.longitude,
    this.enabled = true,
    this.onTap,
  });

  bool get _isPinned => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pinColor = _isPinned
        ? AppColors.accent
        : colorScheme.onSurface.withValues(alpha: 0.4);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _isPinned
              ? AppColors.accent.withValues(alpha: 0.06)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isPinned
                ? AppColors.accent.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isPinned
                  ? Icons.location_on_rounded
                  : Icons.location_on_outlined,
              color: pinColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isPinned ? 'location_pinned'.tr() : 'pick_location'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isPinned
                          ? AppColors.accent
                          : colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isPinned
                        ? '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}'
                        : 'pick_location_hint'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.map_rounded, color: pinColor, size: 18),
          ],
        ),
      ),
    );
  }
}
