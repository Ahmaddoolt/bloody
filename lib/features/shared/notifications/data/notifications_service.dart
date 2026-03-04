// file: lib/shared/features/notifications/data/notifications_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_logger.dart';

class NotificationsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns a realtime stream of notifications for the user
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  /// Marks a specific notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', notificationId);
    } catch (e, stack) {
      AppLogger.error("NotificationsService.markAsRead", e, stack);
    }
  }
}
