// file: lib/actors/receiver/features/map_finder/data/map_finder_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../core/utils/app_logger.dart';
import '../../../../../../core/utils/blood_utils.dart';
import '../../../../../../core/utils/sorting_utils.dart';

class MapFinderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches the current logged-in receiver's profile data
  Future<Map<String, dynamic>?> getReceiverProfile(String userId) async {
    AppLogger.info("Fetching Receiver Profile for: $userId");
    try {
      final data = await _supabase
          .from('profiles')
          .select('blood_type, city')
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e, stack) {
      AppLogger.error("MapFinderService.getReceiverProfile", e, stack);
      return null;
    }
  }

  /// Fetches Donors compatible with the Receiver's blood type
  /// Also filters out donors who donated in the last 90 days.
  Future<List<Map<String, dynamic>>> getCompatibleDonors({
    required String receiverBloodType,
    required int offset,
    required int limit,
    String? receiverCity,
    double? receiverLat,
    double? receiverLng,
  }) async {
    AppLogger.info("Fetching Donors compatible with $receiverBloodType...");
    try {
      final List<String> compatibleDonors = BloodUtils.getCompatibleDonors(receiverBloodType);
      final bool isUniversalReceiver = compatibleDonors.length >= 8;

      var query = _supabase.from('profiles').select().eq('user_type', 'donor');

      if (!isUniversalReceiver) {
        query = query.inFilter('blood_type', compatibleDonors);
      }

      final response = await query.range(offset, offset + limit - 1);
      final List<Map<String, dynamic>> fetchedDonors = List<Map<String, dynamic>>.from(response);

      // ✅ Filter out deferred donors (donated < 90 days ago)
      final now = DateTime.now();
      fetchedDonors.removeWhere((donor) {
        if (donor['last_donation_date'] == null) return false;
        try {
          final lastDate = DateTime.parse(donor['last_donation_date']);
          final readyDate = lastDate.add(const Duration(days: 90));
          return now.isBefore(readyDate);
        } catch (e) {
          return false;
        }
      });

      // ✅ Apply Smart Sorting Algorithm
      SortingUtils.sortDonors(
        fetchedDonors,
        receiverBloodType: receiverBloodType,
        receiverCity: receiverCity,
        receiverLat: receiverLat,
        receiverLng: receiverLng,
      );

      AppLogger.success("Found ${fetchedDonors.length} compatible & eligible donors.");
      return fetchedDonors;
    } catch (e, stack) {
      AppLogger.error("MapFinderService.getCompatibleDonors", e, stack);
      throw e;
    }
  }

  /// Confirms that a donor gave blood.
  /// Rewards points and updates their deferral timer.
  Future<bool> confirmDonation(String donorId) async {
    AppLogger.info("Confirming donation from Donor ID: $donorId");
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // 1. Fetch current points
      final data = await _supabase.from('profiles').select('points').eq('id', donorId).single();
      int currentPoints = (data['points'] as num?)?.toInt() ?? 0;

      // 2. Update points and timestamp
      await _supabase.from('profiles').update({
        'points': currentPoints + 10,
        'last_donation_date': today,
      }).eq('id', donorId);

      // 3. Log in donations table
      await _supabase.from('donations').insert({
        'donor_id': donorId,
        'status': 'completed',
      });

      AppLogger.success("Donation confirmed successfully.");
      return true;
    } catch (e, stack) {
      AppLogger.error("MapFinderService.confirmDonation", e, stack);
      return false;
    }
  }
}
