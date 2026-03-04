// file: lib/actors/admin/features/priority_mgmt/data/priority_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../core/utils/app_logger.dart';

class PriorityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches all users who have requested high priority
  Future<List<Map<String, dynamic>>> fetchPendingRequests() async {
    AppLogger.info("Fetching pending priority requests...");

    final data = await _supabase
        .from('profiles')
        .select('id, username, email, phone, blood_type, city, priority_status')
        .eq('priority_status', 'pending')
        .order('created_at', ascending: true);

    AppLogger.logData("Pending Requests", data);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Updates the user's status and sends them a notification
  Future<void> updatePriorityStatus(String userId, String newStatus) async {
    AppLogger.info("Updating user $userId to status: $newStatus");

    // 1. Update Profile (CRITICAL ACTION)
    await _supabase.from('profiles').update({'priority_status': newStatus}).eq('id', userId);

    AppLogger.success("Profile updated successfully.");

    // 2. Notify User (NON-CRITICAL ACTION)
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': newStatus == 'high' ? 'Priority Approved ✅' : 'Priority Update',
        'body': newStatus == 'high'
            ? 'Your request for high priority status has been approved.'
            : 'Your priority request was not approved.',
        'type': 'system',
        'is_read': false,
      });
      AppLogger.success("Notification sent.");
    } catch (noteError) {
      AppLogger.warning("Could not send notification (Table missing?): $noteError");
    }
  }
}
