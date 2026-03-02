import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LowStockAlertService {
  final SupabaseClient _supabase;
  static const int lowStockThreshold = 5;

  LowStockAlertService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Sends alerts to compatible donors if they haven't donated recently
  Future<bool> sendLowStockAlert({
    required String centerId,
    required String centerName,
    required String bloodType,
    required int currentQuantity,
  }) async {
    try {
      // 1. Get Compatible Donor Types
      final compatibleTypes = _getCompatibleDonorTypes(bloodType);

      // 2. Fetch Eligible Donors (Not deferred)
      final donors = await _fetchEligibleDonors(compatibleTypes);

      if (donors.isEmpty) return false;

      // 3. Prepare Notification Objects
      final notifications = donors
          .map((donor) => {
                'user_id': donor['id'],
                'title': 'Urgent: $bloodType Needed 🩸',
                'body':
                    '$centerName is running low on $bloodType ($currentQuantity bags left). You can help!',
                'type': 'low_stock_alert',
                'center_id': centerId,
                'blood_type': bloodType,
                'is_read': false,
                'created_at': DateTime.now().toIso8601String(),
              })
          .toList();

      // 4. Batch Insert
      await _supabase.from('notifications').insert(notifications);
      debugPrint("Sent ${notifications.length} alerts for $bloodType");

      return true;
    } catch (e) {
      debugPrint("Alert Error: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchEligibleDonors(List<String> types) async {
    final response = await _supabase
        .from('profiles')
        .select('id, blood_type, last_donation_date')
        .eq('user_type', 'donor')
        .inFilter('blood_type', types);

    final now = DateTime.now();

    // Filter out donors who donated in the last 90 days locally
    return (response as List<dynamic>).cast<Map<String, dynamic>>().where((donor) {
      final rawDate = donor['last_donation_date'];
      if (rawDate == null) return true;
      final lastDate = DateTime.tryParse(rawDate.toString());
      if (lastDate == null) return true;

      final readyDate = lastDate.add(const Duration(days: 90));
      return now.isAfter(readyDate);
    }).toList();
  }

  List<String> _getCompatibleDonorTypes(String recipientType) {
    // Standard compatibility logic
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
