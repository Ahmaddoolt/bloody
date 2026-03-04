// file: lib/shared/centers_list/presentation/screens/centers_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/custom_loader.dart';
import '../widgets/admin_center_dialog.dart';
import '../widgets/blood_stock_tile.dart';
import '../widgets/centers_list.dart';
import '../widgets/centers_map.dart';

class CentersScreen extends StatefulWidget {
  const CentersScreen({super.key});

  @override
  State<CentersScreen> createState() => _CentersScreenState();
}

class _CentersScreenState extends State<CentersScreen> {
  final _supabase = Supabase.instance.client;
  final String? _currentUserId = Supabase.instance.client.auth.currentUser?.id;

  List<Map<String, dynamic>> _centers = [];
  bool _isInitialLoading = true;
  bool _fabVisible = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _limit = 20;
  int _offset = 0;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isMapView = false;
  Set<Marker> _markers = {};
  String _searchQuery = '';

  bool _isSortedByStock = false;
  bool _isSortingByStock = false;

  bool get _isSuperAdmin {
    final email = _supabase.auth.currentUser?.email;
    return email == 'adminbloody2026@gmail.com';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() => setState(() {}));
    _fetchCenters();
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) setState(() => _fabVisible = true); });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isMapView) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      _fetchCenters(loadMore: true);
    }
  }

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
      if (mounted)
        setState(() {
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
    }
  }

  Future<void> _sortCentersByStock() async {
    if (_isSortingByStock) return;
    setState(() => _isSortingByStock = true);

    try {
      final inventoryRows = await _supabase.from('center_inventory').select('center_id, quantity');

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

      if (mounted)
        setState(() {
          _centers = sorted;
          _isSortedByStock = true;
          _isSortingByStock = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isSortingByStock = false);
    }
  }

  void _generateMarkers() {
    final Set<Marker> newMarkers = {};
    for (final center in _centers) {
      if (center['latitude'] != null && center['longitude'] != null) {
        newMarkers.add(Marker(
          markerId: MarkerId(center['id'].toString()),
          position: LatLng(center['latitude'], center['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: center['name'],
            snippet: center['address'],
            onTap: () => _showStockModal(center),
          ),
        ));
      }
    }
    setState(() => _markers = newMarkers);
  }

  void _deleteCenter(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Center?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr(), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('delete'.tr())),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('centers').delete().eq('id', id);
        _fetchCenters(loadMore: false);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Error deleting center')));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return FutureBuilder(
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
                              borderRadius: BorderRadius.circular(2)),
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
                                color: AppTheme.primaryRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: AppTheme.primaryRed,
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
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'blood_stock'.tr(),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF5F6FA),
      appBar: _buildAppBar(isDark),
      body: _isInitialLoading
          ? const CustomLoader()
          : Column(
              children: [
                // Sort banner with AnimatedSwitcher
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      SizeTransition(sizeFactor: anim, child: child),
                  child: _isSortedByStock
                      ? _buildSortBanner(key: const ValueKey('banner'))
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
                Expanded(
                  child: _isMapView
                      ? CentersMap(markers: _markers)
                      : CentersList(
                          centers: _centers,
                          isLoading: _isLoadingMore,
                          isSuperAdmin: _isSuperAdmin,
                          currentUserId: _currentUserId,
                          scrollController: _scrollController,
                          onEdit: (c) => _showAdminDialog(center: c),
                          onDelete: (id) => _deleteCenter(id),
                          onViewStock: (c) => _showStockModal(c),
                          onRefresh: () async => await _fetchCenters(loadMore: false),
                        ),
                ),
              ],
            ),
      floatingActionButton: AnimatedScale(
        scale: _fabVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        child: FloatingActionButton(
          heroTag: 'centers_map_fab',
          onPressed: () => setState(() => _isMapView = !_isMapView),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Icon(
            _isMapView ? Icons.list_rounded : Icons.map_rounded,
            size: 24,
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryRed,
      foregroundColor: Colors.white,
      centerTitle: _isMapView,
      elevation: 0,
      title: _isMapView
          ? Text(
              'donation_centers'.tr(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            )
          : _buildSearchBar(isDark),
      actions: [
        // Sort button
        _isSortingByStock
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            : IconButton(
                icon: Icon(
                  Icons.sort_rounded,
                  color: _isSortedByStock ? Colors.amber : Colors.white70,
                ),
                tooltip: _isSortedByStock ? 'Reset sort' : 'Sort by lowest stock',
                onPressed:
                    _isSortedByStock ? () => _fetchCenters(loadMore: false) : _sortCentersByStock,
              ),
        if (_isSuperAdmin)
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, size: 26, color: Colors.white),
            onPressed: () => _showAdminDialog(),
            tooltip: 'Add Center',
          ),
        const SizedBox(width: 4),
      ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.75), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _triggerSearch(),
              textAlignVertical: TextAlignVertical.center,
              style:
                  const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                hintText: 'search_centers'.tr(),
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            GestureDetector(
              onTap: _clearSearch,
              child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.7), size: 18),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: _triggerSearch,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
              ),
              child: const Center(
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
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
          color: AppTheme.primaryRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.primaryRed.withOpacity(0.18), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRed.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.primaryRed, size: 16),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Showing centers with lowest blood stock first.',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _fetchCenters(loadMore: false),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: AppTheme.primaryRed, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
