// file: lib/features/centers/widgets/blood_stock_tile.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class BloodStockTile extends StatelessWidget {
  final String bloodType;
  final int quantity;
  final int neededQuantity;
  final bool isEditing;
  final VoidCallback? onTap;

  const BloodStockTile({
    super.key,
    required this.bloodType,
    required this.quantity,
    required this.neededQuantity,
    this.isEditing = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const int maxCapacity = 50;
    final double progress = (quantity / maxCapacity).clamp(0.0, 1.0);

    Color statusColor;
    String statusText;
    Color bgColor;

    // Theme references
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color;
    final textColor = theme.colorScheme.onSurface;

    if (quantity <= 5) {
      statusColor = AppTheme.primaryRed;
      statusText = "critical_low".tr();
      bgColor = AppTheme.primaryRed.withOpacity(0.15);
    } else if (quantity < 20) {
      statusColor = Colors.orange.shade800;
      if (isDark) statusColor = Colors.orangeAccent;
      statusText = "moderate".tr();
      bgColor = Colors.orange.withOpacity(0.15);
    } else {
      statusColor = Colors.green.shade700;
      if (isDark) statusColor = Colors.greenAccent;
      statusText = "good_stock".tr();
      bgColor = Colors.green.withOpacity(0.15);
    }

    final bool isUrgent = neededQuantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isUrgent ? Border.all(color: AppTheme.primaryRed, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Blood Drop Icon
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle, boxShadow: [
                        BoxShadow(
                            color: statusColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]),
                      child: Text(
                        bloodType,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Main Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: bgColor, borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              Text(
                                "$quantity ${'bags'.tr()}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation(statusColor),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Edit Icon
                    if (isEditing) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.edit_rounded,
                          color: isDark ? Colors.white60 : Colors.grey.shade400, size: 20),
                    ]
                  ],
                ),

                // Urgent Request Badge (Only appears if needed)
                if (isUrgent)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "urgently_needs".tr(args: [neededQuantity.toString()]),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
