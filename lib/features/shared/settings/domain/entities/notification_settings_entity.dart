class NotificationSettingsEntity {
  final String id;
  final String userId;
  final bool receiveLowStockAlerts;
  final bool receiveSystemNotifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationSettingsEntity({
    required this.id,
    required this.userId,
    required this.receiveLowStockAlerts,
    required this.receiveSystemNotifications,
    required this.createdAt,
    required this.updatedAt,
  });

  NotificationSettingsEntity copyWith({
    String? id,
    String? userId,
    bool? receiveLowStockAlerts,
    bool? receiveSystemNotifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      receiveLowStockAlerts:
          receiveLowStockAlerts ?? this.receiveLowStockAlerts,
      receiveSystemNotifications:
          receiveSystemNotifications ?? this.receiveSystemNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
