import '../repositories/settings_repository.dart';

class GetDonationHistory {
  final SettingsRepository _repository;

  GetDonationHistory(this._repository);

  Future<List<Map<String, dynamic>>> call(String userId) {
    return _repository.getDonationHistory(userId);
  }
}
