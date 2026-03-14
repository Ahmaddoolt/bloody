import 'package:bloody/core/utils/app_logger.dart';
import 'package:bloody/features/admin/inventory/domain/entities/inventory_entity.dart';
import 'package:bloody/features/admin/inventory/domain/repositories/inventory_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../low_stock_alert_service.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final _supabase = Supabase.instance.client;
  final LowStockAlertService _alertService = LowStockAlertService();

  static const List<String> _allBloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  Future<List<InventoryItemEntity>> getCenterInventory(String centerId) async {
    try {
      final data = await _supabase
          .from('center_inventory')
          .select()
          .eq('center_id', centerId);

      final existingItems = List<Map<String, dynamic>>.from(data);

      return _allBloodTypes.map((type) {
        final existing = existingItems.firstWhere(
          (e) => e['blood_type'] == type,
          orElse: () => <String, dynamic>{},
        );
        return InventoryItemEntity(
          id: existing['id']?.toString() ?? '',
          bloodType: type,
          quantity: (existing['quantity'] as num?)?.toInt() ?? 0,
          neededQuantity: (existing['needed_quantity'] as num?)?.toInt() ?? 0,
          isUrgent: existing['is_urgent'] ?? false,
        );
      }).toList();
    } catch (e, st) {
      AppLogger.error('InventoryRepositoryImpl.getCenterInventory', e, st);
      rethrow;
    }
  }

  @override
  Future<bool> updateInventoryItem({
    required String centerId,
    required String centerName,
    required String bloodType,
    required int quantity,
    required int neededQuantity,
  }) async {
    final isUrgent = neededQuantity > 0;
    AppLogger.info(
        'Updating $bloodType: Qty=$quantity, Needed=$neededQuantity');

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
    AppLogger.success('Inventory updated for $bloodType');

    if (quantity < LowStockAlertService.lowStockThreshold) {
      AppLogger.warning(
          'Stock low ($quantity) for $bloodType. Triggering alert...');
      final alertSent = await _alertService.sendLowStockAlert(
        centerId: centerId,
        centerName: centerName,
        bloodType: bloodType,
        currentQuantity: quantity,
      );
      return alertSent;
    }

    return false;
  }
}
