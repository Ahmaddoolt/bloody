// file: lib/features/centers/screens/centers_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_loader.dart';
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
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
      }
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

  void _deleteCenter(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Center?'),
        content: const Text('This action cannot be undone.'),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
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

                final textColor = Theme.of(context).colorScheme.onSurface;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final handleColor = isDark ? Colors.grey[700] : Colors.grey[300];

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration:
                          BoxDecoration(color: handleColor, borderRadius: BorderRadius.circular(2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '${center['name']} Stock',
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isMapView
            ? Text('donation_centers'.tr())
            : Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _triggerSearch(),
                  decoration: InputDecoration(
                    hintText: '...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: _clearSearch,
                          ),
                        IconButton(
                          icon: const Icon(Icons.send, color: AppTheme.primaryRed),
                          onPressed: _triggerSearch,
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(left: 15, top: 11),
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
        centerTitle: false,
        actions: [
          _isSortingByStock
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.sort_rounded,
                    color: _isSortedByStock ? AppTheme.primaryRed : Colors.grey,
                  ),
                  tooltip: _isSortedByStock
                      ? 'Sorted by stock ↑ — Tap to reset'
                      : 'Sort by stock (lowest first)',
                  onPressed:
                      _isSortedByStock ? () => _fetchCenters(loadMore: false) : _sortCentersByStock,
                ),
          if (_isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle, size: 28),
              onPressed: () => _showAdminDialog(),
            ),
        ],
      ),
      body: _isInitialLoading
          ? const CustomLoader()
          : Column(
              children: [
                if (_isSortedByStock)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppTheme.primaryRed.withOpacity(0.08),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppTheme.primaryRed, size: 16),
                        const SizedBox(width: 8),
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
                          child: const Icon(Icons.close, color: AppTheme.primaryRed, size: 16),
                        ),
                      ],
                    ),
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
                          onEdit: (center) => _showAdminDialog(center: center),
                          onDelete: (id) => _deleteCenter(id),
                          onViewStock: (center) => _showStockModal(center),
                          onRefresh: () async => await _fetchCenters(loadMore: false),
                        ),
                ),
              ],
            ),
      // ✅ FIX: Added unique heroTag to prevent collision
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'centers_map_fab',
        onPressed: () => setState(() => _isMapView = !_isMapView),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        icon: Icon(_isMapView ? Icons.format_list_bulleted : Icons.map),
        label: Text(_isMapView ? 'List View' : 'nav'.tr()),
      ),
    );
  }
}
