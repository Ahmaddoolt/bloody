// file: lib/core/widgets/user_card.dart
// ignore_for_file: deprecated_member_use
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/blood_utils.dart';

class UserCard extends StatefulWidget {
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
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloodType = widget.userData['blood_type'] ?? '?';
    final email = widget.userData['email'] ?? 'unknown'.tr();
    final phone = widget.userData['phone'] ?? 'no_phone'.tr();
    final city = widget.userData['city'];
    final points = widget.userData['points'] ?? 0;
    final int age = BloodUtils.calculateAge(widget.userData['birth_date']);
    final displayName = widget.userData['username'] ?? email.split('@')[0];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                // Blood type circle with pulsing ring
                AnimatedBuilder(
                  animation: _ringAnim,
                  builder: (context, child) => Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRed
                              .withOpacity(0.15 + 0.2 * _ringAnim.value),
                          blurRadius: 8 + 10 * _ringAnim.value,
                          spreadRadius: 1 + 2 * _ringAnim.value,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryRed, AppTheme.darkRed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
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
                              displayName,
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
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 13, color: Colors.white),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$points',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (age > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '$age ${'years_old'.tr()}',
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
                      if (city != null && city.toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 13, color: subTextColor),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                city.toString(),
                                overflow: TextOverflow.ellipsis,
                                style:
                                    TextStyle(color: subTextColor, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Call Button
                IconButton(
                  onPressed: widget.onCall,
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
