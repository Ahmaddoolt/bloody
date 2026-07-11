import '../repositories/settings_repository.dart';

class UpdateUserProfile {
  final SettingsRepository _repository;

  UpdateUserProfile(this._repository);

  Future<bool> call({
    required String userId,
    String? username,
    String? phone,
    String? bloodType,
    String? city,
    double? latitude,
    double? longitude,
    String? birthDate,
  }) {
    return _repository.updateProfile(
      userId: userId,
      username: username,
      phone: phone,
      bloodType: bloodType,
      city: city,
      latitude: latitude,
      longitude: longitude,
      birthDate: birthDate,
    );
  }
}
