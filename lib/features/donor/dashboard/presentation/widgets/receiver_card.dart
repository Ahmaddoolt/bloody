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

  const ReceiverCard({
    super.key,
    required this.userData,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final bloodType = userData['blood_type'] ?? '?';
    final username = (userData['username']?.toString().isNotEmpty == true)
        ? userData['username']
        : 'receiver'.tr();
    final city = userData['city'];
    final phone = userData['phone'];
    final int age = BloodUtils.calculateAge(userData['birth_date']);

    final colors = Theme.of(context).colorScheme;

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
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),
            // Call Button
            if (phone != null)
              GestureDetector(
                onTap: onCall,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.phone_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
