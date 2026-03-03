// file: lib/actors/receiver/map_finder/data/map_finder_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../core/utils/app_logger.dart';
import '../../../../../../core/utils/blood_utils.dart';
import '../../../../../../core/utils/sorting_utils.dart';

class MapFinderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getReceiverProfile(String userId) async {
    AppLogger.info("Fetching Receiver Profile for: $userId");
    try {
      return await _supabase
          .from('profiles')
          .select('blood_type, city, username')
          .eq('id', userId)
          .maybeSingle();
    } catch (e, stack) {
      AppLogger.error("MapFinderService.getReceiverProfile", e, stack);
      return null;
    }
  }

  /// Fetches compatible, available, non-deferred donors.
  Future<List<Map<String, dynamic>>> getCompatibleDonors({
    required String receiverBloodType,
    required int offset,
    required int limit,
    String? receiverCity,
    double? receiverLat,
    double? receiverLng,
  }) async {
    AppLogger.info("Fetching donors compatible with $receiverBloodType...");
    try {
      final List<String> compatibleDonors = BloodUtils.getCompatibleDonors(receiverBloodType);
      final bool isUniversalReceiver = compatibleDonors.length >= 8;

      var query = _supabase
          .from('profiles')
          .select()
          .eq('user_type', 'donor')
          .eq('is_available', true); // ✅ only available donors

      if (!isUniversalReceiver) {
        query = query.inFilter('blood_type', compatibleDonors);
      }

      final response = await query.range(offset, offset + limit - 1);
      final List<Map<String, dynamic>> donors = List<Map<String, dynamic>>.from(response);

      // Client-side deferral filter (donated < 90 days ago)
      final now = DateTime.now();
      donors.removeWhere((donor) {
        if (donor['last_donation_date'] == null) return false;
        try {
          final last = DateTime.parse(donor['last_donation_date']);
          return now.isBefore(last.add(const Duration(days: 90)));
        } catch (_) {
          return false;
        }
      });

      SortingUtils.sortDonors(donors,
          receiverBloodType: receiverBloodType,
          receiverCity: receiverCity,
          receiverLat: receiverLat,
          receiverLng: receiverLng);

      AppLogger.success("Found ${donors.length} compatible & eligible donors.");
      return donors;
    } catch (e, stack) {
      AppLogger.error("MapFinderService.getCompatibleDonors", e, stack);
      rethrow;
    }
  }

  Future<bool> confirmDonation(String donorId) async {
    AppLogger.info("Confirming donation from Donor ID: $donorId");
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final data = await _supabase.from('profiles').select('points').eq('id', donorId).single();
      final currentPoints = (data['points'] as num?)?.toInt() ?? 0;

      await _supabase.from('profiles').update({
        'points': currentPoints + 10,
        'last_donation_date': today,
      }).eq('id', donorId);

      await _supabase.from('donations').insert({'donor_id': donorId, 'status': 'completed'});

      AppLogger.success("Donation confirmed.");
      return true;
    } catch (e, stack) {
      AppLogger.error("MapFinderService.confirmDonation", e, stack);
      return false;
    }
  }

  /// Broadcasts an urgent request to all matching, available,
  /// non-deferred donors in the same city.
  /// Returns count notified, or -1 on error.
  Future<int> sendBroadcastNotification({
    required String receiverId,
    required String receiverBloodType,
    required String receiverCity,
    required String receiverName,
  }) async {
    AppLogger.info("Broadcasting $receiverBloodType request in $receiverCity");
    try {
      final compatible = BloodUtils.getCompatibleDonors(receiverBloodType);
      final isUniversal = compatible.length >= 8;
      final now = DateTime.now();

      var query = _supabase
          .from('profiles')
          .select('id, blood_type, last_donation_date')
          .eq('user_type', 'donor')
          .eq('is_available', true)
          .eq('city', receiverCity)
          .neq('id', receiverId);

      if (!isUniversal) {
        query = query.inFilter('blood_type', compatible);
      }

      final List<dynamic> candidates = await query;

      // Client-side deferral filter
      final eligible = candidates.where((d) {
        if (d['last_donation_date'] == null) return true;
        try {
          final last = DateTime.parse(d['last_donation_date']);
          return now.isAfter(last.add(const Duration(days: 90)));
        } catch (_) {
          return true;
        }
      }).toList();

      if (eligible.isEmpty) {
        AppLogger.info("No eligible donors for broadcast.");
        return 0;
      }

      final notifications = eligible
          .map<Map<String, dynamic>>((d) => {
                'user_id': d['id'] as String,
                'sender_id': receiverId,
                'type': 'broadcast_request',
                'title': 'Urgent Blood Request 🩸',
                'body':
                    '$receiverName urgently needs $receiverBloodType in $receiverCity. Can you help?',
                'is_read': false,
              })
          .toList();

      await _supabase.from('notifications').insert(notifications);

      AppLogger.success("Broadcast sent to ${eligible.length} donors.");
      return eligible.length;
    } catch (e, stack) {
      AppLogger.error("MapFinderService.sendBroadcastNotification", e, stack);
      return -1;
    }
  }
}
