import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/sorting_utils.dart';

/// Center model for type safety
class CenterModel {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  const CenterModel({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.phone,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory CenterModel.fromJson(Map<String, dynamic> json) {
    return CenterModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      phone: json['phone']?.toString(),
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt?.toIso8601String(),
      };
}

/// Centers state
class CentersState {
  final List<CenterModel> centers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String searchQuery;
  final bool isSortedByStock;
  final bool isSortingByStock;

  const CentersState({
    this.centers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.searchQuery = '',
    this.isSortedByStock = false,
    this.isSortingByStock = false,
  });

  CentersState copyWith({
    List<CenterModel>? centers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? searchQuery,
    bool? isSortedByStock,
    bool? isSortingByStock,
  }) {
    return CentersState(
      centers: centers ?? this.centers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      isSortedByStock: isSortedByStock ?? this.isSortedByStock,
      isSortingByStock: isSortingByStock ?? this.isSortingByStock,
    );
  }
}

/// Riverpod provider for centers state management
class CentersNotifier extends StateNotifier<CentersState> {
  final _supabase = Supabase.instance.client;
  final int _limit = 20;
  int _offset = 0;

  CentersNotifier() : super(const CentersState());

  /// Check if current user is super admin
  bool get isSuperAdmin {
    final email = _supabase.auth.currentUser?.email;
    return email == 'adminbloody2026@gmail.com';
  }

  /// Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch centers with pagination
  Future<void> fetchCenters({bool loadMore = false}) async {
    if (loadMore && (state.isLoadingMore || !state.hasMore)) return;

    state = state.copyWith(
      isLoading: !loadMore,
      isLoadingMore: loadMore,
      error: null,
    );

    if (!loadMore) {
      _offset = 0;
      state = state.copyWith(
        centers: [],
        hasMore: true,
        isSortedByStock: false,
      );
    }

    try {
      var query = _supabase.from('centers').select();

      if (state.searchQuery.isNotEmpty) {
        query = query.ilike('name', '%${state.searchQuery}%');
      }

      final response =
          await query.order('created_at').range(_offset, _offset + _limit - 1);

      final newCenters = (response as List)
          .map((e) => CenterModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final hasMoreData = newCenters.length >= _limit;

      state = state.copyWith(
        centers: loadMore ? [...state.centers, ...newCenters] : newCenters,
        isLoading: false,
        isLoadingMore: false,
        hasMore: hasMoreData,
      );

      _offset += _limit;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Failed to load centers',
      );
    }
  }

  /// Search centers by name
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query.trim());
    await fetchCenters(loadMore: false);
  }

  /// Clear search
  Future<void> clearSearch() async {
    state = state.copyWith(searchQuery: '');
    await fetchCenters(loadMore: false);
  }

  /// Sort centers by blood stock (lowest first)
  Future<void> sortByStock() async {
    if (state.isSortingByStock) return;

    state = state.copyWith(isSortingByStock: true);

    try {
      final inventoryResponse = await _supabase
          .from('center_inventory')
          .select('center_id, quantity');

      final Map<String, int> stockTotals = {};
      for (final row in inventoryResponse as List<dynamic>) {
        final centerId = row['center_id']?.toString() ?? '';
        final qty = (row['quantity'] as num?)?.toInt() ?? 0;
        if (centerId.isNotEmpty) {
          stockTotals[centerId] = (stockTotals[centerId] ?? 0) + qty;
        }
      }

      final sortedCenters = List<CenterModel>.from(state.centers);
      sortedCenters.sort((a, b) {
        final aTotal = stockTotals[a.id] ?? 0;
        final bTotal = stockTotals[b.id] ?? 0;
        return aTotal.compareTo(bTotal);
      });

      // Print sorted centers for debugging
      SortingUtils.printSortedCenters(
        sortedCenters.map((c) => c.toJson()).toList(),
        stockTotals,
      );

      state = state.copyWith(
        centers: sortedCenters,
        isSortedByStock: true,
        isSortingByStock: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSortingByStock: false,
        error: 'Failed to sort by stock',
      );
    }
  }

  /// Reset sorting and refresh
  Future<void> resetSort() async {
    await fetchCenters(loadMore: false);
  }

  /// Delete a center
  Future<bool> deleteCenter(String id) async {
    try {
      await _supabase.from('centers').delete().eq('id', id);
      await fetchCenters(loadMore: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Load more centers (pagination)
  Future<void> loadMore() async {
    await fetchCenters(loadMore: true);
  }

  /// Create a new center
  Future<bool> createCenter({
    required String name,
    required String address,
    required String? city,
    required String? phone,
    required double? latitude,
    required double? longitude,
    String? adminEmail,
  }) async {
    try {
      String? adminId;
      if (adminEmail != null && adminEmail.isNotEmpty) {
        final user = await _supabase
            .from('profiles')
            .select('id')
            .eq('email', adminEmail.trim())
            .maybeSingle();
        if (user != null) {
          adminId = user['id'];
        } else {
          return false;
        }
      }

      final data = <String, dynamic>{
        'name': name.trim(),
        'address': address.trim(),
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
      };
      if (adminId != null) data['admin_id'] = adminId;

      await _supabase.from('centers').insert(data);
      await fetchCenters(loadMore: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update an existing center
  Future<bool> updateCenter({
    required String id,
    required String name,
    required String address,
    required String? city,
    required String? phone,
    required double? latitude,
    required double? longitude,
    String? adminEmail,
  }) async {
    try {
      String? adminId;
      if (adminEmail != null && adminEmail.isNotEmpty) {
        final user = await _supabase
            .from('profiles')
            .select('id')
            .eq('email', adminEmail.trim())
            .maybeSingle();
        if (user != null) {
          adminId = user['id'];
        } else {
          return false;
        }
      }

      final data = <String, dynamic>{
        'name': name.trim(),
        'address': address.trim(),
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
      };
      if (adminId != null) data['admin_id'] = adminId;

      await _supabase.from('centers').update(data).eq('id', id);
      await fetchCenters(loadMore: false);
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for centers state
final centersProvider = StateNotifierProvider<CentersNotifier, CentersState>(
  (ref) => CentersNotifier(),
);

/// Provider for isMapView toggle
final isCentersMapViewProvider = StateProvider<bool>((ref) => false);
