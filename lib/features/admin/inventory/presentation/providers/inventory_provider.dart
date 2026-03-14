import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/inventory_entity.dart';
import '../../domain/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl();
});

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryStateEntity>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return InventoryNotifier(repository);
});

class InventoryNotifier extends StateNotifier<InventoryStateEntity> {
  final InventoryRepository _repository;

  InventoryNotifier(this._repository) : super(const InventoryStateEntity());

  Future<void> fetchInventory(String centerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.getCenterInventory(centerId);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> updateItem({
    required String centerId,
    required String centerName,
    required String bloodType,
    required int quantity,
    required int neededQuantity,
  }) async {
    final index = state.items.indexWhere((i) => i.bloodType == bloodType);
    if (index != -1) {
      final updatedItems = List<InventoryItemEntity>.from(state.items);
      updatedItems[index] = updatedItems[index].copyWith(
        quantity: quantity,
        neededQuantity: neededQuantity,
        isUrgent: neededQuantity > 0,
      );
      state = state.copyWith(items: updatedItems);
    }

    try {
      final alertSent = await _repository.updateInventoryItem(
        centerId: centerId,
        centerName: centerName,
        bloodType: bloodType,
        quantity: quantity,
        neededQuantity: neededQuantity,
      );
      return alertSent;
    } catch (e) {
      await fetchInventory(centerId);
      return false;
    }
  }

  void updateItemLocally(String bloodType, int quantity, int neededQuantity) {
    final index = state.items.indexWhere((i) => i.bloodType == bloodType);
    if (index != -1) {
      final updatedItems = List<InventoryItemEntity>.from(state.items);
      updatedItems[index] = updatedItems[index].copyWith(
        quantity: quantity,
        neededQuantity: neededQuantity,
        isUrgent: neededQuantity > 0,
      );
      state = state.copyWith(items: updatedItems);
    }
  }
}
