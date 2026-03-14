import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../domain/entities/notification_settings_entity.dart';
import '../../domain/repositories/notification_settings_repository.dart';
import '../models/notification_settings_model.dart';

class NotificationSettingsRepositoryImpl
    implements NotificationSettingsRepository {
  final SupabaseClient _supabase;

  NotificationSettingsRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  @override
  Future<NotificationSettingsEntity> getSettings(String userId) async {
    try {
      final response = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        await createDefaultSettings(userId);
        final defaultResponse = await _supabase
            .from('notification_preferences')
            .select()
            .eq('user_id', userId)
            .single();
        return NotificationSettingsModel.fromJson(defaultResponse).toEntity();
      }

      return NotificationSettingsModel.fromJson(response).toEntity();
    } catch (e, st) {
      AppLogger.error('NotificationSettingsRepository.getSettings', e, st);
      rethrow;
    }
  }

  @override
  Future<NotificationSettingsEntity> updateSettings({
    required String userId,
    bool? receiveLowStockAlerts,
    bool? receiveSystemNotifications,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (receiveLowStockAlerts != null) {
        updateData['receive_low_stock_alerts'] = receiveLowStockAlerts;
      }
      if (receiveSystemNotifications != null) {
        updateData['receive_system_notifications'] = receiveSystemNotifications;
      }
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('notification_preferences')
          .update(updateData)
          .eq('user_id', userId)
          .select()
          .single();

      return NotificationSettingsModel.fromJson(response).toEntity();
    } catch (e, st) {
      AppLogger.error('NotificationSettingsRepository.updateSettings', e, st);
      rethrow;
    }
  }

  @override
  Future<void> createDefaultSettings(String userId) async {
    try {
      await _supabase.from('notification_preferences').insert({
        'user_id': userId,
        'receive_low_stock_alerts': true,
        'receive_system_notifications': true,
      });
    } catch (e, st) {
      AppLogger.error(
          'NotificationSettingsRepository.createDefaultSettings', e, st);
      rethrow;
    }
  }
}
