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
      try {
        return await _supabase
            .from('profiles')
            .select('blood_type, city, username, blood_request_reason')
            .eq('id', userId)
            .maybeSingle();
      } on PostgrestException catch (error) {
        if (error.code != '42703') rethrow;
        return await _supabase
            .from('profiles')
            .select('blood_type, city, username')
            .eq('id', userId)
            .maybeSingle();
      }
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
      final List<String> compatibleDonors =
          BloodUtils.getCompatibleDonors(receiverBloodType);
      final bool isUniversalReceiver = compatibleDonors.length >= 8;

      var query = _supabase
          .from('profiles')
          .select()
          .eq('user_type', 'donor')
          .eq('is_available', true); // ✅ only available donors

      if (!isUniversalReceiver) {
        query = query.inFilter('blood_type', compatibleDonors);
      }

      if (receiverCity != null && receiverCity.isNotEmpty) {
        query = query.eq('city', receiverCity);
      }

      final response = await query.range(offset, offset + limit - 1);
      final List<Map<String, dynamic>> donors =
          List<Map<String, dynamic>>.from(response);

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

      // 1. Get current points (safe query — no optional columns)
      final data = await _supabase
          .from('profiles')
          .select('points')
          .eq('id', donorId)
          .single();
      final currentPoints = (data['points'] as num?)?.toInt() ?? 0;

      // 2. Update points + last_donation_date
      await _supabase.from('profiles').update({
        'points': currentPoints + 10,
        'last_donation_date': today,
      }).eq('id', donorId);

      // 3. Log donation
      await _supabase
          .from('donations')
          .insert({'donor_id': donorId, 'status': 'completed'});

      AppLogger.success("Donation confirmed.");

      // 4. Send notification (separate — must not break donation)
      _notifyDonorAboutConfirmation(donorId);

      return true;
    } catch (e, stack) {
      AppLogger.error("MapFinderService.confirmDonation", e, stack);
      return false;
    }
  }

  Future<void> _notifyDonorAboutConfirmation(String donorId) async {
    try {
      // Fetch fcm_token + language — resilient to missing columns
      Map<String, dynamic>? profile;
      try {
        profile = await _supabase
            .from('profiles')
            .select('fcm_token, language')
            .eq('id', donorId)
            .maybeSingle();
      } on PostgrestException catch (e) {
        if (e.code != '42703') rethrow;
        profile = await _supabase
            .from('profiles')
            .select('fcm_token')
            .eq('id', donorId)
            .maybeSingle();
      }

      final fcmToken = profile?['fcm_token']?.toString();
      final isArabic = (profile?['language']?.toString() ?? 'ar') == 'ar';

      await _supabase.functions.invoke(
        'notify-donors',
        body: {
          if (fcmToken != null && fcmToken.isNotEmpty) 'tokens': [fcmToken],
          'title': isArabic
              ? '🩸 شكراً لك، بطل!'
              : '🩸 Thank you, hero!',
          'body': isArabic
              ? 'تم تأكيد تبرعك بالدم! لقد أنقذت حياة. ستدخل الآن في فترة تعافي مدتها 90 يوماً. استرح وحافظ على صحتك.'
              : 'Your blood donation has been confirmed! You saved a life. You are now entering a 90-day recovery period. Rest up and stay healthy.',
          'notification_user_id': donorId,
          'notification_title_key': 'donation_confirmed_notif_title',
          'notification_body_key': 'donation_confirmed_notif_body',
          'notification_type': 'donation',
        },
      );
      AppLogger.success('Donor $donorId notified about donation confirmation.');
    } catch (e) {
      AppLogger.warning('MapFinderService._notifyDonorAboutConfirmation: $e');
    }
  }
}
