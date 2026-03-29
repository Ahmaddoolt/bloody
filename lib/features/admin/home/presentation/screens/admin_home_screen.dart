import 'package:bloody/core/constants/app_constants.dart';
import 'package:bloody/core/services/fcm_service.dart';
import 'package:bloody/core/theme/app_colors.dart';
import 'package:bloody/core/theme/app_theme.dart';
import 'package:bloody/core/widgets/app_confirm_dialog.dart';
import 'package:bloody/core/widgets/app_loading_indicator.dart';
import 'package:bloody/features/shared/centers_list/presentation/widgets/blood_stock_tile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bloody/core/widgets/map_toggle_fab.dart';
import 'package:bloody/features/admin/home/domain/entities/admin_home_entity.dart';
import 'package:bloody/features/admin/home/presentation/providers/admin_home_provider.dart';
import 'package:bloody/features/admin/priority_mgmt/presentation/screens/admin_priority_screen.dart';
import 'package:bloody/features/admin/donor_rewards/presentation/screens/admin_donor_rewards_screen.dart';
import 'package:bloody/features/shared/auth/presentation/providers/auth_provider.dart';
import 'package:bloody/features/shared/auth/presentation/screens/login_screen.dart';
import 'package:bloody/features/shared/centers_list/presentation/providers/centers_provider.dart';
import 'package:bloody/features/shared/centers_list/presentation/widgets/admin_center_dialog.dart';
import 'package:bloody/features/shared/centers_list/presentation/widgets/centers_list.dart';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      ref.read(adminHomeProvider.notifier).fetchCenters();
      ref.read(adminHomeProvider.notifier).fetchPendingPriorityCount();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(adminHomeProvider.notifier).fetchCenters(loadMore: true);
    }
  }

  void _generateMarkers(List<CenterEntity> centers) {
    _markers = centers
        .where((c) => c.latitude != null && c.longitude != null)
        .map((c) => Marker(
              markerId: MarkerId(c.id),
              position: LatLng(c.latitude!, c.longitude!),
              infoWindow: InfoWindow(title: c.name, snippet: c.city),
            ))
        .toSet();
  }

  void _deleteCenter(String id) async {
    final confirm = await AppConfirmDialog.show(
      context: context,
      title: 'delete_center'.tr(),
      content: 'delete_center_confirm'.tr(),
      confirmLabel: 'delete'.tr(),
    );

    if (confirm == true) {
      await Supabase.instance.client.from('centers').delete().eq('id', id);
      ref.read(adminHomeProvider.notifier).fetchCenters(loadMore: false);
    }
  }

  void _showStockModal(Map<String, dynamic> center) {
    final colorScheme = Theme.of(context).colorScheme;
    final centerId = center['id'].toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        List<Map<String, dynamic>>? inventory;
        bool isEditing = false;
        final Set<String> sentTypes = {};

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            if (inventory == null) {
              _fetchCenterInventory(centerId)
                  .then((inv) => setSheetState(() => inventory = inv));
            }

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (ctx2, scrollController) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: AppColors.accent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    center['name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'blood_stock'.tr(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(isEditing
                                  ? Icons.done_rounded
                                  : Icons.edit_rounded),
                              color: isEditing
                                  ? Colors.green
                                  : colorScheme.onSurface.withOpacity(0.6),
                              onPressed: () =>
                                  setSheetState(() => isEditing = !isEditing),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      inventory == null
                          ? const Expanded(
                              child:
                                  Center(child: AppLoadingIndicator(size: 30)))
                          : Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                itemCount: inventory!.length,
                                itemBuilder: (_, idx) {
                                  final item = inventory![idx];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: isEditing
                                            ? () => _showEditInventoryDialog(
                                                  centerId: centerId,
                                                  bloodType: item['blood_type'],
                                                  currentQty:
                                                      item['quantity'] ?? 0,
                                                  currentNeededQty:
                                                      item['needed_quantity'] ??
                                                          0,
                                                  onSaved: () {
                                                    _fetchCenterInventory(
                                                            centerId)
                                                        .then((inv) =>
                                                            setSheetState(() =>
                                                                inventory =
                                                                    inv));
                                                  },
                                                )
                                            : null,
                                        child: BloodStockTile(
                                          bloodType: item['blood_type'],
                                          quantity: item['quantity'],
                                          neededQuantity:
                                              item['needed_quantity'],
                                          isEditing: isEditing,
                                        ),
                                      ),
                                      if (!isEditing)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              8, 4, 8, 8),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.notifications_rounded,
                                                  size: 14,
                                                  color: Colors.deepOrange),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'notify_for_blood_type'.tr(
                                                      args: [
                                                        item['blood_type']
                                                            .toString()
                                                      ]),
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey),
                                                ),
                                              ),
                                              Builder(builder: (_) {
                                                final bt = item['blood_type']
                                                    .toString();
                                                final sent =
                                                    sentTypes.contains(bt);
                                                return ElevatedButton(
                                                  onPressed: sent
                                                      ? null
                                                      : () async {
                                                          setSheetState(() =>
                                                              sentTypes
                                                                  .add(bt));
                                                          await _notifyQuiet(
                                                              center, bt);
                                                          await Future.delayed(
                                                              const Duration(
                                                                  seconds: 2));
                                                          if (ctx.mounted) {
                                                            setSheetState(() =>
                                                                sentTypes
                                                                    .remove(
                                                                        bt));
                                                          }
                                                        },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: sent
                                                        ? Colors.green
                                                        : Colors.deepOrange,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                  ),
                                                  child: Icon(
                                                      sent
                                                          ? Icons.check_rounded
                                                          : Icons.send_rounded,
                                                      size: 16),
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showCenterDetailsBottomSheet(Map<String, dynamic> center) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = center['name']?.toString() ?? 'donation_center'.tr();
    final address = center['address']?.toString();
    final city = center['city']?.toString();
    final phone = center['phone']?.toString();
    final latitude = center['latitude'] as double?;
    final longitude = center['longitude'] as double?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.3,
            maxChildSize: 0.7,
            expand: false,
            builder: (ctx2, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: AppColors.accent,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (city != null && city.isNotEmpty)
                                  Text(
                                    context.tr(city),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (address != null && address.isNotEmpty) ...[
                        _buildDetailRow(
                          icon: Icons.location_on_outlined,
                          title: 'address'.tr(),
                          value: address,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (phone != null) ...[
                        _buildDetailRow(
                          icon: Icons.phone_outlined,
                          title: 'phone_number'.tr(),
                          value: phone,
                          colorScheme: colorScheme,
                          onTap: () async {
                            final uri = Uri(scheme: 'tel', path: phone);
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showStockModal(center);
                              },
                              icon: const Icon(Icons.inventory_2_outlined,
                                  size: 20),
                              label: Text('view_stock'.tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          if (latitude != null && longitude != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
                                  );
                                  if (await canLaunchUrl(uri))
                                    await launchUrl(uri);
                                },
                                icon: const Icon(Icons.map_outlined, size: 20),
                                label: Text('open_map'.tr()),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accent,
                                  side:
                                      const BorderSide(color: AppColors.accent),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required ColorScheme colorScheme,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.5))),
                  Text(value,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCenterInventory(
      String centerId) async {
    final response = await Supabase.instance.client
        .from('center_inventory')
        .select()
        .eq('center_id', centerId);

    const allTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    return allTypes.map((type) {
      final existing = (response as List).firstWhere(
        (e) => e['blood_type'] == type,
        orElse: () => <String, dynamic>{},
      );
      return {
        'blood_type': type,
        'quantity': existing['quantity'] ?? 0,
        'needed_quantity': existing['needed_quantity'] ?? 0,
      };
    }).toList();
  }

  void _showNotifyByCitySheet() {
    String? selectedCity;
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'notify_donors_by_city'.tr(),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: InputDecoration(
                      labelText: 'city_label'.tr(),
                      prefixIcon: const Icon(Icons.location_city_rounded),
                      filled: true,
                      fillColor: Theme.of(ctx)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: AppCities.syrianCities
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.tr())))
                        .toList(),
                    onChanged: (val) {
                      setSheetState(() => selectedCity = val);
                      if (val != null) {
                        titleController.text =
                            'urgent_blood_needed'.tr(args: [val.tr()]);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'title'.tr(),
                      filled: true,
                      fillColor: Theme.of(ctx)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'message_optional'.tr(),
                      filled: true,
                      fillColor: Theme.of(ctx)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: selectedCity == null
                        ? null
                        : () async {
                            final city = selectedCity!;
                            Navigator.pop(ctx);
                            final success = await FcmService.notifyDonorsInCity(
                              city: city,
                              title: titleController.text.trim(),
                              body: messageController.text.trim(),
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'notification_sent_to'.tr(args: [city])
                                      : 'notification_failed'.tr()),
                                  backgroundColor:
                                      success ? Colors.green : Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('send_notification'.tr()),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _notifyQuiet(
      Map<String, dynamic> center, String bloodType) async {
    final city = center['city']?.toString() ?? '';
    final centerName = center['name']?.toString() ?? '';
    await FcmService.notifyDonorsInCity(
      city: city,
      bloodType: bloodType,
      title: 'urgent_blood_needed'.tr(args: [city.tr()]),
      body: '$centerName — ${'urgently_needs'.tr(args: [bloodType])}',
    );
  }

  void _notifyForBloodType(
      Map<String, dynamic> center, String bloodType) async {
    final city = center['city']?.toString() ?? '';
    final centerName = center['name']?.toString() ?? '';
    final success = await FcmService.notifyDonorsInCity(
      city: city,
      bloodType: bloodType,
      title: 'urgent_blood_needed'.tr(args: [city.tr()]),
      body: '$centerName — ${'urgently_needs'.tr(args: [bloodType])}',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'notification_sent_to'.tr(args: [city.tr()])
            : 'notification_failed'.tr()),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  Future<void> _showEditInventoryDialog({
    required String centerId,
    required String bloodType,
    required int currentQty,
    required int currentNeededQty,
    required VoidCallback onSaved,
  }) async {
    int qty = currentQty;
    int needed = currentNeededQty;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('$bloodType ${'blood_type'.tr()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('current_stock'.tr(),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.accent,
                    onPressed:
                        qty > 0 ? () => setDialogState(() => qty--) : null,
                  ),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Text('$qty',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.accent,
                    onPressed: () => setDialogState(() => qty++),
                  ),
                ],
              ),
              const Divider(height: 20),
              Text('urgently_needs'.tr(args: ['...']),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.orange,
                    onPressed: needed > 0
                        ? () => setDialogState(() => needed--)
                        : null,
                  ),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Text('$needed',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.orange,
                    onPressed: () => setDialogState(() => needed++),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr(),
                  style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client.from('center_inventory').upsert(
        {
          'center_id': centerId,
          'blood_type': bloodType,
          'quantity': qty,
          'needed_quantity': needed,
        },
        onConflict: 'center_id,blood_type',
      );
      onSaved();
    }
  }

  void _logout() async {
    await ref.read(authNotifierProvider.notifier).signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(adminHomeProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(_isMapView ? 70 : 136),
        child: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            toolbarHeight: 70,
            title: null,
            titleSpacing: 0,
            centerTitle: false,
            bottom: _isMapView
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(66),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF2C2C2C) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.24 : 0.06),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (query) {
                            ref
                                .read(adminHomeProvider.notifier)
                                .search(query.trim());
                          },
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: 'search_centers'.tr(),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                      ref
                                          .read(adminHomeProvider.notifier)
                                          .clearSearch();
                                    },
                                  ),
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Material(
                                    color: AppTheme.primaryRed,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        ref
                                            .read(adminHomeProvider.notifier)
                                            .search(
                                                _searchController.text.trim());
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            suffixIconConstraints:
                                const BoxConstraints(minWidth: 0, minHeight: 0),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            hintStyle: TextStyle(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.38),
                            ),
                          ),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
            actions: [
              // Reward donors button
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.emoji_events_rounded,
                      size: 26, color: Color(0xFFFF8F00)),
                  tooltip: 'reward_donors'.tr(),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminDonorRewardsScreen()),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_rounded,
                      size: 26, color: Colors.deepOrange),
                  tooltip: 'notify_donors_by_city'.tr(),
                  onPressed: _showNotifyByCitySheet,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.star_rounded,
                          size: 26, color: Colors.orange),
                      tooltip: 'priority_requests'.tr(),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminPriorityScreen()),
                        );
                        ref
                            .read(adminHomeProvider.notifier)
                            .fetchPendingPriorityCount();
                      },
                    ),
                    if (state.pendingPriorityCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryRed,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            state.pendingPriorityCount > 9
                                ? '9+'
                                : '${state.pendingPriorityCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: state.isSortedByStock
                      ? AppTheme.primaryRed
                      : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: state.isSortingByStock
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: AppLoadingIndicator(
                          size: 22,
                          strokeWidth: 2,
                          color: AppTheme.primaryRed,
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.sort_rounded,
                          size: 26,
                          color: state.isSortedByStock
                              ? Colors.white
                              : Colors.blue,
                        ),
                        tooltip: state.isSortedByStock
                            ? 'Sorted by Stock'
                            : 'sort_by_stock'.tr(),
                        onPressed: state.isSortedByStock
                            ? () => ref
                                .read(adminHomeProvider.notifier)
                                .fetchCenters(loadMore: false)
                            : () => ref
                                .read(adminHomeProvider.notifier)
                                .sortCentersByStock(),
                      ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded,
                      size: 28, color: Colors.green),
                  tooltip: 'add_center'.tr(),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AdminCenterDialog(
                      center: null,
                      onSuccess: () => ref
                          .read(adminHomeProvider.notifier)
                          .fetchCenters(loadMore: false),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      color: colorScheme.onSurface),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  onSelected: (val) {
                    if (val == 'en') {
                      context.setLocale(const Locale('en'));
                    } else if (val == 'ar') {
                      context.setLocale(const Locale('ar'));
                    } else if (val == 'logout') {
                      _logout();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'en',
                      child: Row(children: [
                        Icon(Icons.language, color: Colors.blue),
                        SizedBox(width: 12),
                        Text('English'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'ar',
                      child: Row(children: [
                        Icon(Icons.language, color: Colors.green),
                        SizedBox(width: 12),
                        Text('العربية'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded, color: Colors.red),
                          const SizedBox(width: 12),
                          Text('log_out'.tr(),
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: state.isLoading
          ? const AppLoadingCenter()
          : Column(
              children: [
                _buildCityFilter(state),
                if (state.isSortedByStock)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppTheme.primaryRed.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.sort_rounded,
                            color: AppTheme.primaryRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'sort_by_stock_info'.tr(),
                            style: TextStyle(
                              color: AppTheme.primaryRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ref
                              .read(adminHomeProvider.notifier)
                              .fetchCenters(loadMore: false),
                          child: const Icon(Icons.close,
                              color: AppTheme.primaryRed, size: 16),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child:
                      _isMapView ? _buildMapView(state) : _buildListView(state),
                ),
              ],
            ),
      floatingActionButton: MapToggleFab(
        heroTag: 'admin_map_fab',
        isMapView: _isMapView,
        onToggle: () => setState(() => _isMapView = !_isMapView),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCityFilter(AdminHomeState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DropdownButtonFormField<String?>(
        initialValue: state.selectedCity,
        decoration: InputDecoration(
          labelText: 'city_label'.tr(),
          prefixIcon: const Icon(Icons.location_city_rounded),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text('all_cities'.tr()),
          ),
          ...AppCities.syrianCities.map(
            (city) => DropdownMenuItem<String?>(
              value: city,
              child: Text(city.tr()),
            ),
          ),
        ],
        onChanged: (city) {
          ref.read(adminHomeProvider.notifier).setCityFilter(city);
        },
      ),
    );
  }

  Widget _buildListView(AdminHomeState state) {
    // Convert CenterEntity to CenterModel
    final centers = state.centers
        .map((e) => CenterModel(
              id: e.id,
              name: e.name,
              city: e.city,
              address: e.address,
              phone: e.phone,
              latitude: e.latitude,
              longitude: e.longitude,
              createdAt: e.createdAt,
            ))
        .toList();

    return CentersList(
      centers: centers,
      isLoading: state.isLoadingMore,
      isSuperAdmin: true,
      scrollController: _scrollController,
      onEdit: (center) => showDialog(
        context: context,
        builder: (_) => AdminCenterDialog(
          center: center.toJson(),
          onSuccess: () => ref
              .read(adminHomeProvider.notifier)
              .fetchCenters(loadMore: false),
        ),
      ),
      onDelete: (id) => _deleteCenter(id),
      onViewStock: (center) => _showStockModal(center.toJson()),
      onViewDetails: (center) => _showCenterDetailsBottomSheet(center.toJson()),
      onRefresh: () =>
          ref.read(adminHomeProvider.notifier).fetchCenters(loadMore: false),
    );
  }

  Widget _buildMapView(AdminHomeState state) {
    _generateMarkers(state.centers);

    if (state.centers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('no_centers'.tr()),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          state.centers.first.latitude ?? 33.5,
          state.centers.first.longitude ?? 36.3,
        ),
        zoom: 11,
      ),
      markers: _markers,
      onTap: (_) {},
    );
  }
}
