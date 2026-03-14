import '../../domain/entities/notification_settings_entity.dart';

class NotificationSettingsModel {
  final String id;
  final String userId;
  final bool receiveLowStockAlerts;
  final bool receiveSystemNotifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationSettingsModel({
    required this.id,
    required this.userId,
    required this.receiveLowStockAlerts,
    required this.receiveSystemNotifications,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      receiveLowStockAlerts: json['receive_low_stock_alerts'] as bool? ?? true,
      receiveSystemNotifications:
          json['receive_system_notifications'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'receive_low_stock_alerts': receiveLowStockAlerts,
      'receive_system_notifications': receiveSystemNotifications,
    };
  }

  NotificationSettingsEntity toEntity() {
    return NotificationSettingsEntity(
      id: id,
      userId: userId,
      receiveLowStockAlerts: receiveLowStockAlerts,
      receiveSystemNotifications: receiveSystemNotifications,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
