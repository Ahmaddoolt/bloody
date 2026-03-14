import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../providers/centers_provider.dart';

/// Compact center card matching receiver card design
/// Clean, minimalist, ~72px height
class CenterCard extends StatelessWidget {
  final CenterModel center;
  final bool isSuperAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewStock;
  final VoidCallback? onViewDetails;
  final VoidCallback? onCall;
  final VoidCallback? onMap;

  const CenterCard({
    super.key,
    required this.center,
    this.isSuperAdmin = false,
    this.onEdit,
    this.onDelete,
    this.onViewStock,
    this.onViewDetails,
    this.onCall,
    this.onMap,
  });

  Future<void> _makeCall(String? phone) async {
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final name = center.name.isNotEmpty ? center.name : 'donation_center'.tr();
    final address = center.address?.isNotEmpty == true
        ? center.address!
        : 'no_address'.tr();
    final city = center.city;
    final phone = center.phone;
    final latitude = center.latitude;
    final longitude = center.longitude;

    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onViewDetails,
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
              // Center Icon
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
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 24,
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
                      name,
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
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            city != null && city.isNotEmpty
                                ? '${context.tr(city)}, $address'
                                : address,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // View Stock Button
                  GestureDetector(
                    onTap: onViewStock,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.accent,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Call Button
                  if (phone != null)
                    GestureDetector(
                      onTap: onCall ?? () => _makeCall(phone),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.phone_rounded,
                          color: AppColors.accent,
                          size: 18,
                        ),
                      ),
                    ),
                  if (phone != null) const SizedBox(width: 6),
                  // Map Button
                  if (latitude != null && longitude != null)
                    GestureDetector(
                      onTap: onMap ?? () => _openMap(latitude, longitude),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          color: Colors.blue,
                          size: 18,
                        ),
                      ),
                    ),
                  // Admin Menu
                  if (isSuperAdmin) ...[
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: colors.onSurface.withOpacity(0.5),
                        size: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (val) {
                        if (val == 'edit') onEdit?.call();
                        if (val == 'delete') onDelete?.call();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded,
                                  color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              Text('edit'.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Text('delete'.tr(),
                                  style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
