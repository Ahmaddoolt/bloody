import '../entities/user_profile_entity.dart';
import '../repositories/settings_repository.dart';

class GetUserProfile {
  final SettingsRepository _repository;

  GetUserProfile(this._repository);

  Future<UserProfileEntity?> call(String userId) {
    return _repository.getProfile(userId);
  }
}
