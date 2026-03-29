import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../providers/receiver_map_provider.dart';

class ReceiverHomeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final ReceiverMapState state;
  final VoidCallback? onPriorityTap;

  const ReceiverHomeAppBar({
    super.key,
    required this.state,
    this.onPriorityTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.accent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: preferredSize.height,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentDark, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HeaderBadge(
                      icon: Icons.bloodtype_rounded,
                      label: state.neededBloodType ?? '--',
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderBadge(
                          icon: Icons.people_alt_rounded,
                          label: '${state.donors.length}',
                        ),
                        if (onPriorityTap != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: onPriorityTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.star_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'find_donors'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.donors.length} ${'donor'.tr()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    if (state.city != null && state.city!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          state.city!.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
