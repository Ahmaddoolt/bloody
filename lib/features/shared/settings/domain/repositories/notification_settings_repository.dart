import '../entities/notification_settings_entity.dart';

abstract class NotificationSettingsRepository {
  Future<NotificationSettingsEntity> getSettings(String userId);

  Future<NotificationSettingsEntity> updateSettings({
    required String userId,
    bool? receiveLowStockAlerts,
    bool? receiveSystemNotifications,
  });

  Future<void> createDefaultSettings(String userId);
}
