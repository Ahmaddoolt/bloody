// file: lib/features/centers/widgets/blood_stock_tile.dart
// ignore_for_file: deprecated_member_use
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class BloodStockTile extends StatefulWidget {
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
  State<BloodStockTile> createState() => _BloodStockTileState();
}

class _BloodStockTileState extends State<BloodStockTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _urgentCtrl;
  late final Animation<double> _urgentAnim;

  @override
  void initState() {
    super.initState();
    _urgentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _urgentAnim = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _urgentCtrl, curve: Curves.easeInOut));
    if (widget.neededQuantity > 0) {
      _urgentCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _urgentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int maxCapacity = 50;
    final double progress = (widget.quantity / maxCapacity).clamp(0.0, 1.0);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color;
    final textColor = theme.colorScheme.onSurface;

    Color statusColor;
    String statusText;
    Color bgColor;

    if (widget.quantity <= 5) {
      statusColor = AppTheme.primaryRed;
      statusText = 'critical_low'.tr();
      bgColor = AppTheme.primaryRed.withOpacity(0.15);
    } else if (widget.quantity < 20) {
      statusColor = isDark ? Colors.orangeAccent : Colors.orange.shade800;
      statusText = 'moderate'.tr();
      bgColor = Colors.orange.withOpacity(0.15);
    } else {
      statusColor = isDark ? Colors.greenAccent : Colors.green.shade700;
      statusText = 'good_stock'.tr();
      bgColor = Colors.green.withOpacity(0.15);
    }

    final bool isUrgent = widget.neededQuantity > 0;

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
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Blood type circle with status ring
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.bloodType,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(6)),
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
                                '${widget.quantity} ${'bags'.tr()}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Animated progress bar
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: progress),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (_, value, __) => ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 7,
                                backgroundColor:
                                    isDark ? Colors.grey[700] : Colors.grey[200],
                                valueColor:
                                    AlwaysStoppedAnimation(statusColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (widget.isEditing) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.edit_rounded,
                          color: isDark ? Colors.white60 : Colors.grey.shade400,
                          size: 20),
                    ],
                  ],
                ),

                // Pulsing urgent badge
                if (isUrgent)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ScaleTransition(
                      scale: _urgentAnim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryRed, AppTheme.darkRed],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryRed.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Blinking dot
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'urgently_needs'.tr(
                                  args: [widget.neededQuantity.toString()]),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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
