import 'package:bloody/core/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Compact profile card row for settings
/// Matches the style of other toggle rows
class ProfileCard extends StatelessWidget {
  final String username;
  final String? email;
  final String? bloodType;
  final String? city;
  final VoidCallback onEditTap;

  const ProfileCard({
    super.key,
    required this.username,
    this.email,
    this.bloodType,
    this.city,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Avatar - Blue for user profile
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF1976D2),
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
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (bloodType != null || city != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (bloodType != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bloodType!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (city != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: colors.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              context.tr(city!),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Edit button
          GestureDetector(
            onTap: onEditTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.outline.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.edit_rounded,
                color: colors.onSurface.withOpacity(0.5),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
