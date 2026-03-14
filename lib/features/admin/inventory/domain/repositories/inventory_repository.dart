import '../entities/inventory_entity.dart';

abstract class InventoryRepository {
  Future<List<InventoryItemEntity>> getCenterInventory(String centerId);
  Future<bool> updateInventoryItem({
    required String centerId,
    required String centerName,
    required String bloodType,
    required int quantity,
    required int neededQuantity,
  });
}
