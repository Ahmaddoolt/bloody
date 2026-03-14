import 'package:bloody/core/notifications/notification_templates.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LowStockAlertService {
  final SupabaseClient _supabase;
  static const int lowStockThreshold = 5;

  LowStockAlertService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  Future<bool> sendLowStockAlert({
    required String centerId,
    required String centerName,
    required String bloodType,
    required int currentQuantity,
  }) async {
    try {
      final compatibleTypes = _getCompatibleDonorTypes(bloodType);
      if (compatibleTypes.isEmpty) {
        debugPrint(
            '[LowStockAlertService] No compatible donor types found for $bloodType');
        return false;
      }

      final donors = await _fetchEligibleDonors(compatibleTypes);

      if (donors.isEmpty) {
        debugPrint(
            '[LowStockAlertService] No eligible donors found for $bloodType');
        return false;
      }

      // Generate localized notifications for each donor
      final donorIds = donors
          .map((donor) => donor['id'])
          .whereType<String>()
          .toSet()
          .toList();

      // Get donor languages for localized notifications
      final donorLanguages = <String, String>{};
      for (final donor in donors) {
        donorLanguages[donor['id']] = donor['language'] as String? ?? 'ar';
      }

      // Insert notifications to database with proper localization
      final notifications = donors.map((donor) {
        final language = donorLanguages[donor['id']] ?? 'ar';
        final notification = NotificationTemplates.getNotification(
          'low_stock',
          language,
          params: {
            'blood_type': bloodType,
            'center': centerName,
          },
        );
        return {
          'user_id': donor['id'],
          'title': notification['title'],
          'body': notification['body'],
          'type': 'low_stock_alert',
          'center_id': centerId,
          'blood_type': bloodType,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      await _supabase.from('notifications').insert(notifications);
      debugPrint(
          '[LowStockAlertService] Inserted ${notifications.length} notifications to database');

      // Use default Arabic for FCM (server will handle individual localization if needed)
      final notification = NotificationTemplates.getNotification(
        'low_stock',
        'ar',
        params: {
          'blood_type': bloodType,
          'center': centerName,
        },
      );
      final title = notification['title']!;
      final body = notification['body']!;

      try {
        final response = await _supabase.functions.invoke(
          'notify-donors',
          body: {
            'donorIds': donorIds,
            'title': title,
            'body': body,
            'type': 'low_stock_alert',
            'center_id': centerId,
            'blood_type': bloodType,
          },
        );

        final sentCount = _extractSentCount(response.data);
        if (sentCount == 0) {
          debugPrint(
              '[LowStockAlertService] notify-donors returned 0 successful sends for $bloodType. Response: ${response.data}');
          return false;
        }

        debugPrint(
            '[LowStockAlertService] Sent FCM to $sentCount of ${donorIds.length} eligible donors via notify-donors');
      } catch (e) {
        debugPrint('[LowStockAlertService] Error calling notify-donors: $e');
        return false;
      }

      return true;
    } catch (e, st) {
      debugPrint('[LowStockAlertService] ERROR: $e');
      debugPrint('[LowStockAlertService] StackTrace: $st');
      return false;
    }
  }

  int _extractSentCount(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return (responseData['sent'] as num?)?.toInt() ?? 0;
    }

    if (responseData is Map) {
      final sent = responseData['sent'];
      return sent is num ? sent.toInt() : 0;
    }

    return 0;
  }

  Future<List<Map<String, dynamic>>> _fetchEligibleDonors(
      List<String> types) async {
    final response = await _supabase
        .from('profiles')
        .select('id, blood_type, last_donation_date')
        .eq('user_type', 'donor')
        .eq('is_available', true)
        .inFilter('blood_type', types);

    final now = DateTime.now();

    final deferredFiltered =
        (response as List<dynamic>).cast<Map<String, dynamic>>().where((donor) {
      final rawDate = donor['last_donation_date'];
      if (rawDate == null) return true;
      final lastDate = DateTime.tryParse(rawDate.toString());
      if (lastDate == null) return true;

      final readyDate = lastDate.add(const Duration(days: 90));
      return now.isAfter(readyDate);
    }).toList();

    if (deferredFiltered.isEmpty) return [];

    final donorIds = deferredFiltered.map((d) => d['id'] as String).toList();

    try {
      final preferencesResponse = await _supabase
          .from('notification_preferences')
          .select('user_id, receive_low_stock_alerts')
          .inFilter('user_id', donorIds);

      final preferencesMap = <String, bool>{};
      for (final pref in preferencesResponse as List<dynamic>) {
        preferencesMap[pref['user_id'] as String] =
            pref['receive_low_stock_alerts'] as bool? ?? true;
      }

      return deferredFiltered.where((donor) {
        final donorId = donor['id'] as String;
        return preferencesMap[donorId] ?? true;
      }).toList();
    } catch (e) {
      debugPrint(
          '[LowStockAlertService] No preferences table, using all eligible donors');
      return deferredFiltered;
    }
  }

  List<String> _getCompatibleDonorTypes(String recipientType) {
    switch (recipientType) {
      case 'A+':
        return ['A+', 'A-', 'O+', 'O-'];
      case 'A-':
        return ['A-', 'O-'];
      case 'B+':
        return ['B+', 'B-', 'O+', 'O-'];
      case 'B-':
        return ['B-', 'O-'];
      case 'AB+':
        return ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
      case 'AB-':
        return ['A-', 'B-', 'AB-', 'O-'];
      case 'O+':
        return ['O+', 'O-'];
      case 'O-':
        return ['O-'];
      default:
        return [];
    }
  }
}
