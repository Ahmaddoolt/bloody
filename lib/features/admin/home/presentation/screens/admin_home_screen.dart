// file: lib/actors/admin/features/home/presentation/screens/admin_home_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../core/services/fcm_service.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_loader.dart';
import '../../../../shared/auth/presentation/screens/login_screen.dart';
import '../../../../shared/centers_list/presentation/widgets/admin_center_dialog.dart';
import '../../../../shared/centers_list/presentation/widgets/blood_stock_tile.dart';
import '../../../../shared/centers_list/presentation/widgets/centers_list.dart';
import '../../../../shared/centers_list/presentation/widgets/centers_map.dart';
import '../../../priority_mgmt/presentation/admin_priority_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _supabase = Supabase.instance.client;
  final String? _currentUserId = Supabase.instance.client.auth.currentUser?.id;

  List<Map<String, dynamic>> _centers = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _limit = 20;
  int _offset = 0;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isMapView = false;
  Set<Marker> _markers = {};
  String _searchQuery = '';

  // Sort state — Feature 3
  bool _isSortedByStock = false;
  bool _isSortingByStock = false;

  // Pending priority count for badge — Feature 2
  int _pendingPriorityCount = 0;

  final bool _isSuperAdmin = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() => setState(() {}));
    _fetchCenters();
    _fetchPendingPriorityCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Scroll ────────────────────────────────────────────────────────────────

  void _onScroll() {
    if (_isMapView) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      _fetchCenters(loadMore: true);
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void _triggerSearch() {
    final newQuery = _searchController.text.trim();
    if (_searchQuery != newQuery) {
      setState(() => _searchQuery = newQuery);
      _fetchCenters(loadMore: false);
    }
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    if (_searchQuery.isNotEmpty) {
      setState(() => _searchQuery = '');
      _fetchCenters(loadMore: false);
    }
    FocusScope.of(context).unfocus();
  }

  // ── Data Fetching ─────────────────────────────────────────────────────────

  Future<void> _fetchCenters({bool loadMore = false}) async {
    if (loadMore && (_isLoadingMore || !_hasMore)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isInitialLoading = true;
        _centers.clear();
        _offset = 0;
        _hasMore = true;
        _isSortedByStock = false;
      }
    });

    try {
      var query = _supabase.from('centers').select();
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$_searchQuery%');
      }

      final data = await query.order('created_at').range(_offset, _offset + _limit - 1);

      if (mounted) {
        if (data.length < _limit) _hasMore = false;
        setState(() {
          _centers.addAll(List<Map<String, dynamic>>.from(data));
          _offset += _limit;
          _isLoadingMore = false;
          _isInitialLoading = false;
          _generateMarkers();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  /// Fetches total inventory per center and sorts [_centers] ascending
  /// by total stock — Feature 3: lowest stock shown first.
  Future<void> _sortCentersByStock() async {
    if (_isSortingByStock) return;
    setState(() => _isSortingByStock = true);

    try {
      final inventoryRows = await _supabase.from('center_inventory').select('center_id, quantity');

      // Build a totals map: centerId → totalBags
      final Map<String, int> stockTotals = {};
      for (final row in inventoryRows as List<dynamic>) {
        final centerId = row['center_id'].toString();
        final qty = (row['quantity'] as num?)?.toInt() ?? 0;
        stockTotals[centerId] = (stockTotals[centerId] ?? 0) + qty;
      }

      final sorted = List<Map<String, dynamic>>.from(_centers);
      sorted.sort((a, b) {
        final aTotal = stockTotals[a['id'].toString()] ?? 0;
        final bTotal = stockTotals[b['id'].toString()] ?? 0;
        return aTotal.compareTo(bTotal);
      });

      if (mounted) {
        setState(() {
          _centers = sorted;
          _isSortedByStock = true;
          _isSortingByStock = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSortingByStock = false);
    }
  }

  /// Fetches the count of pending priority requests to show as badge.
  Future<void> _fetchPendingPriorityCount() async {
    try {
      final data = await _supabase.from('profiles').select('id').eq('priority_status', 'pending');

      if (mounted) {
        setState(() => _pendingPriorityCount = (data as List<dynamic>).length);
      }
    } catch (_) {}
  }

  // ── Map Markers ───────────────────────────────────────────────────────────

  void _generateMarkers() {
    final Set<Marker> newMarkers = {};
    for (final center in _centers) {
      if (center['latitude'] != null && center['longitude'] != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(center['id'].toString()),
            position: LatLng(center['latitude'], center['longitude']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: center['name'],
              snippet: center['address'],
              onTap: () => _showStockModal(center),
            ),
          ),
        );
      }
    }
    setState(() => _markers = newMarkers);
  }

  // ── Center Actions ────────────────────────────────────────────────────────

  void _deleteCenter(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Center?'),
        content: const Text('This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('delete'.tr(), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('centers').delete().eq('id', id);
        _fetchCenters(loadMore: false);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Error deleting center')));
        }
      }
    }
  }

  void _showAdminDialog({Map<String, dynamic>? center}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdminCenterDialog(
        center: center,
        onSuccess: () => _fetchCenters(loadMore: false),
      ),
    );
  }

  void _showStockModal(Map<String, dynamic> center) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: FutureBuilder(
                future: _supabase.from('center_inventory').select().eq('center_id', center['id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CustomLoader(size: 30));
                  }

                  final List<dynamic> rawData = snapshot.data as List? ?? [];
                  const allTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

                  final inventory = allTypes.map((type) {
                    final existing = rawData.firstWhere(
                      (e) => e['blood_type'] == type,
                      orElse: () => <String, dynamic>{},
                    );
                    return {
                      'blood_type': type,
                      'quantity': existing['quantity'] ?? 0,
                      'needed_quantity': existing['needed_quantity'] ?? 0,
                    };
                  }).toList();

                  final textColor = theme.colorScheme.onSurface;
                  final handleColor = isDark ? Colors.grey[700] : Colors.grey[300];

                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                            color: handleColor, borderRadius: BorderRadius.circular(10)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.inventory_2_outlined,
                                  color: AppTheme.primaryRed),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    center['name'],
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: textColor),
                                  ),
                                  Text(
                                    'Live Stock Inventory',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              ),
            );
          },
        );
      },
    );
  }

  // ── Notify Donors ─────────────────────────────────────────────────────────

  void _showNotifyDonorsSheet(Map<String, dynamic> center) {
    final city = center['city'] as String? ?? '';
    final messageController = TextEditingController(
      text: 'Urgent blood donation needed in $city. Please check the app.',
    );
    final titleController = TextEditingController(text: 'Blood Donation Alert');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Notify Donors in $city',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await FcmService.notifyDonorsInCity(
                      city: city,
                      title: titleController.text.trim(),
                      body: messageController.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Notification sent to donors in $city'),
                          backgroundColor: Colors.deepOrange,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _navigateToPriorityScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminPriorityScreen()),
    );
    // Refresh count on return
    _fetchPendingPriorityCount();
  }

  void _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 70,
        title: _isMapView
            ? Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: theme.colorScheme.onSurface,
                ),
              )
            : Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _triggerSearch(),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Search Centers...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: _clearSearch,
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded,
                                    color: AppTheme.primaryRed),
                                onPressed: _triggerSearch,
                              ),
                            ],
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              ),
        centerTitle: false,
        actions: [
          // ── Priority Requests Button with Badge ───────────────────
          Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.star_rounded, size: 26, color: Colors.orange),
                  tooltip: 'Priority Requests',
                  onPressed: _navigateToPriorityScreen,
                ),
              ),
              if (_pendingPriorityCount > 0)
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
                      _pendingPriorityCount > 9 ? '9+' : '$_pendingPriorityCount',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          // ── Sort by Stock Button ──────────────────────────────────
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: _isSortedByStock
                  ? AppTheme.primaryRed
                  : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isSortingByStock
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      Icons.sort_rounded,
                      size: 26,
                      color: _isSortedByStock ? Colors.white : Colors.blue,
                    ),
                    tooltip: _isSortedByStock ? 'Sorted by Stock ↑' : 'Sort by Stock',
                    onPressed: _isSortedByStock
                        ? () => _fetchCenters(loadMore: false)
                        : _sortCentersByStock,
                  ),
          ),

          // ── Add Center Button ─────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, size: 28, color: Colors.green),
              tooltip: 'Add Center',
              onPressed: () => _showAdminDialog(),
            ),
          ),

          // ── More Menu ─────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: theme.colorScheme.onSurface),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      Text('log_out'.tr(), style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isInitialLoading
          ? const CustomLoader()
          : Column(
              children: [
                // ── Sort Banner ─────────────────────────────────────
                if (_isSortedByStock)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.sort_rounded, color: AppTheme.primaryRed, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Sorted by lowest stock first — most critical centers shown first.',
                            style: TextStyle(
                              color: AppTheme.primaryRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _fetchCenters(loadMore: false),
                          child: const Icon(Icons.close, color: AppTheme.primaryRed, size: 16),
                        ),
                      ],
                    ),
                  ),

                // ── Centers Content ─────────────────────────────────
                Expanded(
                  child: _isMapView
                      ? CentersMap(markers: _markers)
                      : CentersList(
                          centers: _centers,
                          isLoading: _isLoadingMore,
                          isSuperAdmin: _isSuperAdmin,
                          currentUserId: _currentUserId,
                          scrollController: _scrollController,
                          onEdit: (center) => _showAdminDialog(center: center),
                          onDelete: (id) => _deleteCenter(id),
                          onViewStock: (center) => _showStockModal(center),
                          onRefresh: () async => await _fetchCenters(loadMore: false),
                          onNotifyDonors: _showNotifyDonorsSheet,
                        ),
                ),
              ],
            ),
      // ✅ Added unique heroTag to prevent FAB collision in IndexedStack
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_map_fab',
        onPressed: () => setState(() => _isMapView = !_isMapView),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: Icon(_isMapView ? Icons.format_list_bulleted_rounded : Icons.map),
        label: Text(
          _isMapView ? 'List View' : 'nav'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
