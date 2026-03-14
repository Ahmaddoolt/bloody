import 'package:bloody/core/services/fcm_service.dart';
import 'package:bloody/core/theme/app_theme.dart';
import 'package:bloody/core/widgets/app_loading_indicator.dart';
import 'package:bloody/core/widgets/map_toggle_fab.dart';
import 'package:bloody/features/admin/home/domain/entities/admin_home_entity.dart';
import 'package:bloody/features/admin/home/presentation/providers/admin_home_provider.dart';
import 'package:bloody/features/admin/priority_mgmt/presentation/screens/admin_priority_screen.dart';
import 'package:bloody/features/shared/auth/presentation/providers/auth_provider.dart';
import 'package:bloody/features/shared/centers_list/presentation/providers/centers_provider.dart';
import 'package:bloody/features/shared/centers_list/presentation/widgets/admin_center_dialog.dart';
import 'package:bloody/features/shared/centers_list/presentation/widgets/centers_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  void _showNotifyDonorsSheet(Map<String, dynamic> center) {
    final city = center['city'] ?? '';
    final titleController = TextEditingController(
      text: 'urgent_blood_needed'.tr(args: [city]),
    );
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              'notify_donors_in'.tr(args: [city]),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'title'.tr(),
                filled: true,
                fillColor: Theme.of(ctx)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
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
                      backgroundColor: success ? Colors.green : Colors.red,
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
      ),
    );
  }

  void _deleteCenter(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_center'.tr()),
        content: Text('delete_center_confirm'.tr()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.from('centers').delete().eq('id', id);
      ref.read(adminHomeProvider.notifier).fetchCenters(loadMore: false);
    }
  }

  void _logout() async {
    await ref.read(authNotifierProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(adminHomeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 70,
        title: _isMapView
            ? Text(
                'admin_dashboard'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: colorScheme.onSurface,
                ),
              )
            : Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (query) {
                    ref.read(adminHomeProvider.notifier).search(query);
                  },
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'search_centers'.tr(),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(adminHomeProvider.notifier)
                                      .clearSearch();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded,
                                    color: AppTheme.primaryRed),
                                onPressed: () {
                                  ref
                                      .read(adminHomeProvider.notifier)
                                      .search(_searchController.text);
                                },
                              ),
                            ],
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
        centerTitle: false,
        actions: [
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
                      color: state.isSortedByStock ? Colors.white : Colors.blue,
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
              icon:
                  const Icon(Icons.add_rounded, size: 28, color: Colors.green),
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
              icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface),
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
      body: state.isLoading
          ? const AppLoadingCenter()
          : Column(
              children: [
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
        isMapView: _isMapView,
        onToggle: () => setState(() => _isMapView = !_isMapView),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
        zoom: 7,
      ),
      markers: _markers,
      onTap: (_) {},
    );
  }
}
