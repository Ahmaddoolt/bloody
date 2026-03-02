// file: lib/actors/admin/features/inventory/data/inventory_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/app_logger.dart';
import 'low_stock_alert_service.dart';

class InventoryService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LowStockAlertService _alertService = LowStockAlertService();

  /// Fetches the inventory from the database
  Future<List<Map<String, dynamic>>> getCenterInventory(String centerId) async {
    AppLogger.info("Fetching inventory for Center ID: $centerId");
    final data = await _supabase.from('center_inventory').select().eq('center_id', centerId);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Saves the inventory and triggers the alert if needed
  /// Returns `true` if a low stock alert was actually sent out.
  Future<bool> updateInventoryItem({
    required String centerId,
    required String centerName,
    required String bloodType,
    required int quantity,
    required int neededQuantity,
  }) async {
    final isUrgent = neededQuantity > 0;
    AppLogger.info("Saving $bloodType: Qty=$quantity, Needed=$neededQuantity");

    // 1. Save to Database
    await _supabase.from('center_inventory').upsert(
      {
        'center_id': centerId,
        'blood_type': bloodType,
        'quantity': quantity,
        'needed_quantity': neededQuantity,
        'is_urgent': isUrgent,
      },
      onConflict: 'center_id, blood_type',
    );
    AppLogger.success("Inventory updated for $bloodType");

    // 2. Feature 4: Trigger Low Stock Alert
    if (quantity < LowStockAlertService.lowStockThreshold) {
      AppLogger.warning("Stock low ($quantity) for $bloodType. Triggering alert...");

      final alertSent = await _alertService.sendLowStockAlert(
        centerId: centerId,
        centerName: centerName,
        bloodType: bloodType,
        currentQuantity: quantity,
      );
      return alertSent; // True if users were notified
    }

    return false; // No alert sent
  }
}
