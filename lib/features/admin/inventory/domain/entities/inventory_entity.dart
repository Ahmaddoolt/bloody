class InventoryItemEntity {
  final String id;
  final String bloodType;
  final int quantity;
  final int neededQuantity;
  final bool isUrgent;

  const InventoryItemEntity({
    required this.id,
    required this.bloodType,
    required this.quantity,
    required this.neededQuantity,
    required this.isUrgent,
  });

  factory InventoryItemEntity.fromJson(Map<String, dynamic> json) {
    return InventoryItemEntity(
      id: json['id']?.toString() ?? '',
      bloodType: json['blood_type'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      neededQuantity: (json['needed_quantity'] as num?)?.toInt() ?? 0,
      isUrgent: json['is_urgent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'blood_type': bloodType,
        'quantity': quantity,
        'needed_quantity': neededQuantity,
        'is_urgent': isUrgent,
      };

  InventoryItemEntity copyWith({
    String? id,
    String? bloodType,
    int? quantity,
    int? neededQuantity,
    bool? isUrgent,
  }) {
    return InventoryItemEntity(
      id: id ?? this.id,
      bloodType: bloodType ?? this.bloodType,
      quantity: quantity ?? this.quantity,
      neededQuantity: neededQuantity ?? this.neededQuantity,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
}

class InventoryStateEntity {
  final List<InventoryItemEntity> items;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const InventoryStateEntity({
    this.items = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  InventoryStateEntity copyWith({
    List<InventoryItemEntity>? items,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return InventoryStateEntity(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
