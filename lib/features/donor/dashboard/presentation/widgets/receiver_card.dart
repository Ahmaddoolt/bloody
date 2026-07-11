import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/blood_utils.dart';

/// Compact receiver card for donor dashboard
/// Follows Flutter UI Design skill:
/// - 8px grid spacing
/// - Max 3 font sizes
/// - Clean minimalist design
/// - ~80px height (compact)
class ReceiverCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onCall;
  final VoidCallback? onTap;

  const ReceiverCard({
    super.key,
    required this.userData,
    required this.onCall,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bloodType = userData['blood_type'] ?? '?';
    final username = (userData['username']?.toString().isNotEmpty == true)
        ? userData['username']
        : 'receiver'.tr();
    final city = userData['city'];
    final hasPhone = userData['phone']?.toString().trim().isNotEmpty == true;
    final int age = BloodUtils.calculateAge(userData['birth_date']);
    final situation = userData['blood_request_reason']?.toString().trim();
    final isHighPriority = userData['priority_status'] == 'high';

    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              // Blood Type Badge
              Container(
                width: 48,
                height: 48,
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
                      fontSize: 16,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            username,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isHighPriority) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (city != null) ...[
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
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.cake_outlined,
                          size: 12,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$age ${'years_old'.tr()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    if (situation?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${'receiver_situation_preview'.tr()}: $situation',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.65),
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: hasPhone ? onCall : null,
                  tooltip:
                      hasPhone ? 'tap_to_call'.tr() : 'no_phone_available'.tr(),
                  icon: Icon(
                    Icons.call_rounded,
                    size: 18,
                    color: hasPhone
                        ? AppColors.accent
                        : colors.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
