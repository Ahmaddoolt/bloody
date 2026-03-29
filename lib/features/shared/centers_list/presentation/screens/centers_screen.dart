// file: lib/shared/centers_list/presentation/screens/centers_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/utils/map_marker_helper.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../../core/utils/map_marker_helper.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/map_toggle_fab.dart';
import '../providers/centers_provider.dart';
import '../widgets/admin_center_dialog.dart';
import '../widgets/blood_stock_tile.dart';
import '../widgets/centers_list.dart';
import '../widgets/centers_map.dart';

class CentersScreen extends ConsumerStatefulWidget {
  const CentersScreen({super.key});

  @override
  ConsumerState<CentersScreen> createState() => _CentersScreenState();
}

class _CentersScreenState extends ConsumerState<CentersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  BitmapDescriptor? _centerMarkerIcon;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() => setState(() {}));

    // Load custom marker
    _loadMarkerIcon();

    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(centersProvider.notifier).fetchCenters();
    });
  }

  Future<void> _loadMarkerIcon() async {
    final icon = await MapMarkerHelper.getHospitalMarker();
    if (mounted) {
      setState(() {
        _centerMarkerIcon = icon;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isMapView = ref.read(isCentersMapViewProvider);
    if (isMapView) return;

    final state = ref.read(centersProvider);
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!state.isLoadingMore && state.hasMore) {
        ref.read(centersProvider.notifier).loadMore();
      }
    }
  }

  void _triggerSearch() {
    final query = _searchController.text.trim();
    ref.read(centersProvider.notifier).search(query);
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(centersProvider.notifier).clearSearch();
    FocusScope.of(context).unfocus();
  }

  Future<void> _refresh() async {
    await ref.read(centersProvider.notifier).fetchCenters(loadMore: false);
  }

  void _deleteCenter(String id) async {
    final confirm = await AppConfirmDialog.show(
      context: context,
      title: 'delete_center'.tr(),
      content: 'delete_center_confirm'.tr(),
      confirmLabel: 'delete'.tr(),
    );

    if (confirm == true) {
      final success = await ref.read(centersProvider.notifier).deleteCenter(id);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_deleting_center'.tr())),
        );
      }
    }
  }

  void _showAdminDialog({Map<String, dynamic>? center}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdminCenterDialog(
        center: center,
        onSuccess: () => _refresh(),
      ),
    );
  }

  void _showStockModal(Map<String, dynamic> center) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
            builder: (context, scrollController) {
              return FutureBuilder(
                future: _fetchCenterInventory(center['id'].toString()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: AppLoadingIndicator(size: 30),
                    );
                  }

                  final inventory = snapshot.data ?? [];

                  return Column(
                    children: [
                      // Handle
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
                      // Header
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
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: inventory.length,
                          itemBuilder: (ctx, idx) {
                            final item = inventory[idx];
                            return BloodStockTile(
                              bloodType: item['blood_type'],
                              quantity: item['quantity'],
                              neededQuantity: item['needed_quantity'],
                              isEditing: false,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
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

    // Debug print to check city value
    debugPrint('Center city value: "$city"');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.3,
            maxChildSize: 0.6,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
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
                      // Icon and Name
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  AppColors.accent.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: Colors.white,
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
                                if (city != null && city.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    context.tr(city),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Full Address
                      if (address != null && address.isNotEmpty) ...[
                        _buildDetailRow(
                          icon: Icons.location_on_outlined,
                          title: 'address'.tr(),
                          value: address,
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Phone
                      if (phone != null) ...[
                        _buildDetailRow(
                          icon: Icons.phone_outlined,
                          title: 'phone_number'.tr(),
                          value: phone,
                          colorScheme: colorScheme,
                          onTap: () async {
                            final uri = Uri(scheme: 'tel', path: phone);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                                icon: const Icon(Icons.map_outlined, size: 20),
                                label: Text('open_map'.tr()),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accent,
                                  side: BorderSide(color: AppColors.accent),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
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

  Set<Marker> _generateMarkers(List<Map<String, dynamic>> centers) {
    return centers
        .where((c) => c['latitude'] != null && c['longitude'] != null)
        .map((center) {
      return Marker(
        markerId: MarkerId(center['id'].toString()),
        position: LatLng(
          center['latitude'] as double,
          center['longitude'] as double,
        ),
        icon: _centerMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: center['name']?.toString(),
          snippet: center['address']?.toString(),
          onTap: () => _showStockModal(center),
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(centersProvider);
    final isMapView = ref.watch(isCentersMapViewProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(state, isMapView, colorScheme),
      body: state.isLoading && state.centers.isEmpty
          ? const Center(child: AppLoadingIndicator())
          : Column(
              children: [
                // Sort banner
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      SizeTransition(sizeFactor: anim, child: child),
                  child: state.isSortedByStock
                      ? _buildSortBanner(key: const ValueKey('banner'))
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
                Expanded(
                  child: isMapView
                      ? CentersMap(
                          markers: _generateMarkers(
                            state.centers.map((c) => c.toJson()).toList(),
                          ),
                        )
                      : CentersList(
                          centers: state.centers,
                          isLoading: state.isLoadingMore,
                          isSuperAdmin:
                              ref.read(centersProvider.notifier).isSuperAdmin,
                          scrollController: _scrollController,
                          onEdit: (c) => _showAdminDialog(center: c.toJson()),
                          onDelete: (id) => _deleteCenter(id),
                          onViewStock: (c) => _showStockModal(c.toJson()),
                          onViewDetails: (c) =>
                              _showCenterDetailsBottomSheet(c.toJson()),
                          onRefresh: _refresh,
                        ),
                ),
              ],
            ),
      floatingActionButton: MapToggleFab(
        isMapView: isMapView,
        onToggle: () =>
            ref.read(isCentersMapViewProvider.notifier).state = !isMapView,
        heroTag: 'centers_map_toggle',
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    CentersState state,
    bool isMapView,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 120,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentDark, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row with actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'donation_centers'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sort button
                        if (state.isSortingByStock)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: AppLoadingIndicator(
                              size: 18,
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          IconButton(
                            icon: Icon(
                              Icons.sort_rounded,
                              color: state.isSortedByStock
                                  ? Colors.amber
                                  : Colors.white70,
                              size: 22,
                            ),
                            tooltip: state.isSortedByStock
                                ? 'reset_sort'.tr()
                                : 'sort_by_stock'.tr(),
                            onPressed: state.isSortedByStock
                                ? () => ref
                                    .read(centersProvider.notifier)
                                    .resetSort()
                                : () => ref
                                    .read(centersProvider.notifier)
                                    .sortByStock(),
                          ),
                        // Add button for super admin
                        if (ref.read(centersProvider.notifier).isSuperAdmin)
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                            onPressed: () => _showAdminDialog(),
                            tooltip: 'add_center'.tr(),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search bar
                _buildSearchBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.9),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _triggerSearch(),
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'search_centers'.tr(),
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            GestureDetector(
              onTap: _clearSearch,
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: _triggerSearch,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBanner({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.18),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.accent,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'sorted_by_lowest_stock'.tr(),
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => ref.read(centersProvider.notifier).resetSort(),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.accent,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
