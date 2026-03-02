// file: lib/features/centers/widgets/center_card.dart
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
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final Uri googleMapsUrl =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Permission Logic: Super Admin OR Assigned Manager
    final bool isAssignedManager = currentUserId != null && center['admin_id'] == currentUserId;
    final bool canManage = isSuperAdmin || isAssignedManager;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: AppTheme.primaryRed, size: 28),
                ),
                const SizedBox(width: 14),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center['name'] ?? 'unknown'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              center['address'] ?? 'No address',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Super Admin Actions Menu
                if (isSuperAdmin)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: isDark ? Colors.grey : Colors.grey[600]),
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Buttons Row
            Row(
              children: [
                // Stock Button (Manage or View)
                Expanded(
                  flex: 3,
                  child: canManage
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Color(0xff8E0000) : Color(0xff8E0000),
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.inventory_2, size: 18),
                          label: Text("manage_stock".tr()),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CenterInventoryScreen(center: center),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                          label: Text("view_stock".tr()),
                          onPressed: () => onViewStock(center),
                        ),
                ),
                const SizedBox(width: 8),

                // Call Button
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.phone, color: AppTheme.primaryRed),
                    onPressed: () => _makeCall(center['phone']),
                    tooltip: "Call",
                  ),
                ),
                const SizedBox(width: 8),

                // Map Button (New)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.map, color: Colors.blue),
                    onPressed: () => _openMap(center['latitude'], center['longitude']),
                    tooltip: "Open Maps",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
