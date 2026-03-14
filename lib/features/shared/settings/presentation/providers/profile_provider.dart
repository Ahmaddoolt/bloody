import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfileEntity?>>(
        (ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return ProfileNotifier(repository);
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfileEntity?>> {
  final SettingsRepository _repository;

  ProfileNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getProfile(userId);
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> updateProfile({
    required String userId,
    String? username,
    String? phone,
    String? bloodType,
    String? city,
    String? birthDate,
  }) async {
    try {
      final success = await _repository.updateProfile(
        userId: userId,
        username: username,
        phone: phone,
        bloodType: bloodType,
        city: city,
        birthDate: birthDate,
      );

      if (success) {
        final currentProfile = state.value;
        if (currentProfile != null) {
          state = AsyncValue.data(currentProfile.copyWith(
            username: username ?? currentProfile.username,
            phone: phone ?? currentProfile.phone,
            bloodType: bloodType ?? currentProfile.bloodType,
            city: city ?? currentProfile.city,
            birthDate: birthDate ?? currentProfile.birthDate,
          ));
        }
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  void clearProfile() {
    state = const AsyncValue.data(null);
  }
}
