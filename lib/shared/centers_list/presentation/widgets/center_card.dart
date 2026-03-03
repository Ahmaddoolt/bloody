// file: lib/shared/centers_list/presentation/widgets/center_card.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../actors/admin/inventory/presentation/screens/center_inventory_screen.dart';
import '../../../../core/theme/app_theme.dart';

class CenterCard extends StatelessWidget {
  final Map<String, dynamic> center;
  final bool isSuperAdmin;
  final String? currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Map<String, dynamic>) onViewStock;

  const CenterCard({
    super.key,
    required this.center,
    required this.isSuperAdmin,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
    required this.onViewStock,
  });

  Future<void> _makeCall(String? phone) async {
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAssignedManager = currentUserId != null && center['admin_id'] == currentUserId;
    final bool canManage = isSuperAdmin || isAssignedManager;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: AppTheme.primaryRed, size: 26),
                ),
                const SizedBox(width: 14),
                // Name + address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center['name'] ?? 'unknown'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              center['address'] ?? 'No address',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Super admin menu
                if (isSuperAdmin)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: isDark ? Colors.grey[400] : Colors.grey[600], size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit_rounded, color: Colors.blue, size: 17)),
                          const SizedBox(width: 10),
                          const Text('Edit'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.delete_rounded, color: Colors.red, size: 17)),
                          const SizedBox(width: 10),
                          const Text('Delete', style: TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────
          Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12)),

          // ── Action buttons ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                // Primary: manage / view stock
                Expanded(
                  child: canManage
                      ? _ActionButton(
                          label: 'manage_stock'.tr(),
                          icon: Icons.inventory_2_rounded,
                          backgroundColor: AppTheme.darkRed,
                          foregroundColor: Colors.white,
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CenterInventoryScreen(center: center))),
                        )
                      : _ActionButton(
                          label: 'view_stock'.tr(),
                          icon: Icons.remove_red_eye_outlined,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.grey.withOpacity(0.08),
                          foregroundColor: isDark ? Colors.white70 : Colors.black54,
                          borderColor:
                              isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                          onPressed: () => onViewStock(center),
                        ),
                ),
                const SizedBox(width: 8),
                // Call icon button
                _IconActionButton(
                  icon: Icons.phone_rounded,
                  color: AppTheme.primaryRed,
                  tooltip: 'Call',
                  onPressed: () => _makeCall(center['phone']),
                ),
                const SizedBox(width: 8),
                // Map icon button
                _IconActionButton(
                  icon: Icons.map_rounded,
                  color: Colors.blue.shade700,
                  tooltip: 'Open Maps',
                  onPressed: () => _openMap(center['latitude'], center['longitude']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: borderColor != null ? BorderSide(color: borderColor!, width: 1) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
