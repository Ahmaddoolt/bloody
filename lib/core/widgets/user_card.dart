// file: lib/core/widgets/user_card.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/blood_utils.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onTap;
  final VoidCallback onCall;

  const UserCard({
    super.key,
    required this.userData,
    required this.onTap,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final bloodType = userData['blood_type'] ?? '?';
    final email = userData['email'] ?? 'unknown'.tr();
    final phone = userData['phone'] ?? 'no_phone'.tr();
    final points = userData['points'] ?? 0;
    final int age = BloodUtils.calculateAge(userData['birth_date']);

    // Theme references
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Blood Type Circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryRed, AppTheme.darkRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryRed.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    bloodType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              email.split('@')[0],
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (points > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.amber, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 10, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    "$points",
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber),
                                  ),
                                ],
                              ),
                            )
                          ]
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (age > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "$age ${'years_old'.tr()}",
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: subTextColor),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: TextStyle(color: subTextColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Call Button
                IconButton(
                  onPressed: onCall,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.15),
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.phone),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
