import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../../../../core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<UserProfileEntity?> getProfile(String userId) async {
    AppLogger.info('SettingsRepositoryImpl.getProfile for user: $userId');
    try {
      final response =
          await _supabase.from('profiles').select().eq('id', userId).single();

      return UserProfileEntity(
        id: response['id'] ?? '',
        username: response['username'] ?? '',
        email: response['email'] ?? '',
        phone: response['phone'],
        bloodType: response['blood_type'],
        city: response['city'],
        birthDate: response['birth_date'],
        userType: response['user_type'] ?? 'donor',
        isAvailable: response['is_available'] ?? false,
        priorityStatus: response['priority_status'],
        lastDonationDate: response['last_donation_date'] != null
            ? DateTime.tryParse(response['last_donation_date'])
            : null,
        fcmToken: response['fcm_token'],
      );
    } catch (e, stack) {
      AppLogger.error('SettingsRepositoryImpl.getProfile', e, stack);
      return null;
    }
  }

  @override
  Future<bool> updateProfile({
    required String userId,
    String? username,
    String? phone,
    String? bloodType,
    String? city,
    String? birthDate,
  }) async {
    AppLogger.info('SettingsRepositoryImpl.updateProfile for user: $userId');
    try {
      final updateData = <String, dynamic>{};
      if (username != null) updateData['username'] = username;
      if (phone != null) updateData['phone'] = phone;
      if (bloodType != null) updateData['blood_type'] = bloodType;
      if (city != null) updateData['city'] = city;
      if (birthDate != null) updateData['birth_date'] = birthDate;

      if (updateData.isEmpty) return true;

      await _supabase.from('profiles').update(updateData).eq('id', userId);

      AppLogger.success('Profile updated successfully');
      return true;
    } catch (e, stack) {
      AppLogger.error('SettingsRepositoryImpl.updateProfile', e, stack);
      return false;
    }
  }

  @override
  Future<bool> toggleAvailability({
    required String userId,
    required bool isAvailable,
  }) async {
    AppLogger.info(
        'SettingsRepositoryImpl.toggleAvailability: $isAvailable for $userId');
    try {
      await _supabase
          .from('profiles')
          .update({'is_available': isAvailable}).eq('id', userId);

      AppLogger.success('Availability updated -> $isAvailable');
      return true;
    } catch (e, stack) {
      AppLogger.error('SettingsRepositoryImpl.toggleAvailability', e, stack);
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDonationHistory(String userId) async {
    AppLogger.info(
        'SettingsRepositoryImpl.getDonationHistory for user: $userId');
    try {
      final response = await _supabase
          .from('donations')
          .select('*, centers(name)')
          .eq('donor_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      AppLogger.error('SettingsRepositoryImpl.getDonationHistory', e, stack);
      return [];
    }
  }

  @override
  Future<void> logout() async {
    AppLogger.info('SettingsRepositoryImpl.logout');
    try {
      await _supabase.auth.signOut();
      AppLogger.success('User signed out successfully');
    } catch (e, stack) {
      AppLogger.error('SettingsRepositoryImpl.logout', e, stack);
    }
  }
}
