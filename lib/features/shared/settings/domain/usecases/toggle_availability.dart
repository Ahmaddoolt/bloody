import '../repositories/settings_repository.dart';

class ToggleAvailability {
  final SettingsRepository _repository;

  ToggleAvailability(this._repository);

  Future<bool> call({
    required String userId,
    required bool isAvailable,
  }) async {
    final result = await _repository.toggleAvailability(
      userId: userId,
      isAvailable: isAvailable,
    );
    return result;
  }
}
