// file: lib/shared/settings/data/settings_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_logger.dart';

class SettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    AppLogger.info("Loading profile for user: $userId");
    try {
      return await _supabase.from('profiles').select().eq('id', userId).single();
    } catch (e, stack) {
      AppLogger.error("SettingsService.getProfile", e, stack);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDonationHistory(String userId) async {
    try {
      final response = await _supabase
          .from('donations')
          .select('*, centers(name)')
          .eq('donor_id', userId)
          .order('created_at', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      AppLogger.error("SettingsService.getDonationHistory", e, stack);
      return [];
    }
  }

  Future<bool> updateProfile({
    required String userId,
    required String username,
    required String phone,
    required String? bloodType,
    required String? city,
    required String? birthDate,
  }) async {
    try {
      await _supabase.from('profiles').update({
        'username': username,
        'phone': phone,
        'blood_type': bloodType,
        'city': city,
        'birth_date': birthDate,
      }).eq('id', userId);
      return true;
    } catch (e, stack) {
      AppLogger.error("SettingsService.updateProfile", e, stack);
      return false;
    }
  }

  /// Toggles the donor's `is_available` flag.
  /// Returns the new value on success, null on failure.
  Future<bool?> toggleAvailability({
    required String userId,
    required bool isAvailable,
  }) async {
    AppLogger.info("Toggling is_available=$isAvailable for $userId");
    try {
      await _supabase.from('profiles').update({'is_available': isAvailable}).eq('id', userId);
      AppLogger.success("Availability updated → $isAvailable");
      return isAvailable;
    } catch (e, stack) {
      AppLogger.error("SettingsService.toggleAvailability", e, stack);
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e, stack) {
      AppLogger.error("SettingsService.logout", e, stack);
    }
  }
}
