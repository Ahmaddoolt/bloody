// file: lib/core/models/blood_center_model.dart
import 'package:flutter/foundation.dart';

/// Immutable model for a blood donation center.
/// [stock] maps blood type → quantity, e.g. {'A+': 12, 'O-': 3}.
@immutable
class BloodCenterModel {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final double? latitude;
  final double? longitude;

  /// Key = blood type (e.g. 'A+'), Value = number of bags available.
  final Map<String, int> stock;

  const BloodCenterModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.latitude,
    this.longitude,
    required this.stock,
  });

  // ── Computed props ──────────────────────────────────────────────────────

  /// Total bags across all blood types.
  int get totalStock => stock.values.fold(0, (sum, v) => sum + v);

  /// Blood types whose quantity is critically low (< 5 bags).
  List<String> get lowStockTypes =>
      stock.entries.where((e) => e.value < 5).map((e) => e.key).toList();

  /// True if any blood type is critically low.
  bool get hasLowStock => lowStockTypes.isNotEmpty;

  // ── Factory ─────────────────────────────────────────────────────────────

  /// Builds a [BloodCenterModel] from a Supabase `centers` row, merging in
  /// a list of inventory rows from `center_inventory`.
  factory BloodCenterModel.fromSupabase(
    Map<String, dynamic> centerRow,
    List<Map<String, dynamic>> inventoryRows,
  ) {
    final Map<String, int> stock = {};
    for (final row in inventoryRows) {
      final type = row['blood_type'] as String?;
      final qty = (row['quantity'] as num?)?.toInt() ?? 0;
      if (type != null) stock[type] = qty;
    }

    return BloodCenterModel(
      id: centerRow['id'].toString(),
      name: (centerRow['name'] as String?) ?? 'Unknown Center',
      address: (centerRow['address'] as String?) ?? '',
      phone: centerRow['phone'] as String?,
      latitude: (centerRow['latitude'] as num?)?.toDouble(),
      longitude: (centerRow['longitude'] as num?)?.toDouble(),
      stock: stock,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'stock': stock,
        'total_stock': totalStock,
      };
}

// ── Sorting utility ────────────────────────────────────────────────────────

/// Sorts centers by [totalStock] ascending so the most-depleted center
/// appears first, making it easy to prioritise restocking.
///
/// Usage:
/// ```dart
/// final sorted = CenterSortingUtils.byTotalStockAscending(centers);
/// ```
class CenterSortingUtils {
  const CenterSortingUtils._();

  /// Returns a new list sorted by [totalStock] — lowest first.
  static List<BloodCenterModel> byTotalStockAscending(
    List<BloodCenterModel> centers,
  ) {
    final sorted = List<BloodCenterModel>.from(centers);
    sorted.sort((a, b) => a.totalStock.compareTo(b.totalStock));
    return sorted;
  }

  /// Returns a new list sorted by the stock of a [specificType] — lowest first.
  static List<BloodCenterModel> byTypeStockAscending(
    List<BloodCenterModel> centers,
    String specificType,
  ) {
    final sorted = List<BloodCenterModel>.from(centers);
    sorted.sort((a, b) {
      final aQty = a.stock[specificType] ?? 0;
      final bQty = b.stock[specificType] ?? 0;
      return aQty.compareTo(bQty);
    });
    return sorted;
  }

  /// Returns only centers that have at least one [lowStockTypes] entry.
  static List<BloodCenterModel> filterLowStock(
    List<BloodCenterModel> centers,
  ) =>
      centers.where((c) => c.hasLowStock).toList();
}
