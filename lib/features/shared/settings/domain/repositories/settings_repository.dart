import '../entities/user_profile_entity.dart';

abstract class SettingsRepository {
  Future<UserProfileEntity?> getProfile(String userId);
  Future<bool> updateProfile({
    required String userId,
    String? username,
    String? phone,
    String? bloodType,
    String? city,
    String? birthDate,
  });
  Future<bool> toggleAvailability({
    required String userId,
    required bool isAvailable,
  });
  Future<List<Map<String, dynamic>>> getDonationHistory(String userId);
  Future<void> logout();
}
