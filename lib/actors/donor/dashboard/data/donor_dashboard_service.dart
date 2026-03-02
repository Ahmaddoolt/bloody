// file: lib/actors/donor/features/dashboard/data/donor_dashboard_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/utils/blood_utils.dart';
import '../../../../../core/utils/sorting_utils.dart';

class DonorDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches the current logged-in donor's profile data
  Future<Map<String, dynamic>?> getDonorProfile(String userId) async {
    AppLogger.info("Fetching Donor Profile for: $userId");
    try {
      final data = await _supabase
          .from('profiles')
          .select('blood_type, points, last_donation_date, city')
          .eq('id', userId)
          .single();
      return data;
    } catch (e, stack) {
      AppLogger.error("DonorDashboardService.getDonorProfile", e, stack);
      return null;
    }
  }

  /// Fetches Receivers compatible with the Donor's blood type
  Future<List<Map<String, dynamic>>> getCompatibleReceivers({
    required String donorBloodType,
    required int offset,
    required int limit,
    String? donorCity,
    double? donorLat,
    double? donorLng,
  }) async {
    AppLogger.info("Fetching Receivers compatible with $donorBloodType...");
    try {
      final List<String> compatibleTypes = BloodUtils.getCompatibleReceivers(donorBloodType);
      final bool isUniversalDonor = donorBloodType == 'O-';

      var query = _supabase.from('profiles').select().eq('user_type', 'receiver');

      if (!isUniversalDonor) {
        query = query.inFilter('blood_type', compatibleTypes);
      }

      final response = await query.range(offset, offset + limit - 1);
      final List<Map<String, dynamic>> receivers = List<Map<String, dynamic>>.from(response);

      // Apply Smart Sorting
      SortingUtils.sortNeedyUsers(
        receivers,
        donorBloodType: donorBloodType,
        donorCity: donorCity,
        donorLat: donorLat,
        donorLng: donorLng,
      );

      AppLogger.success("Found ${receivers.length} compatible receivers.");
      return receivers;
    } catch (e, stack) {
      AppLogger.error("DonorDashboardService.getCompatibleReceivers", e, stack);
      throw e;
    }
  }

  /// Confirms a donation: Updates points, sets date, and logs it.
  Future<bool> confirmDonation(String donorId, int currentPoints) async {
    AppLogger.info("Confirming donation for $donorId. Current points: $currentPoints");
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // 1. Update points and date
      await _supabase.from('profiles').update({
        'points': currentPoints + 10,
        'last_donation_date': today,
      }).eq('id', donorId);

      // 2. Log in donations table
      await _supabase.from('donations').insert({
        'donor_id': donorId,
        'status': 'completed',
      });

      AppLogger.success("Donation confirmed successfully.");
      return true;
    } catch (e, stack) {
      AppLogger.error("DonorDashboardService.confirmDonation", e, stack);
      return false;
    }
  }
}
