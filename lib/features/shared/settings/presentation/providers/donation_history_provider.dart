import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/settings_repository.dart';
import 'profile_provider.dart';

final donationHistoryProvider = StateNotifierProvider<DonationHistoryNotifier,
    AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return DonationHistoryNotifier(repository);
});

class DonationHistoryNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final SettingsRepository _repository;

  DonationHistoryNotifier(this._repository) : super(const AsyncValue.data([]));

  Future<void> loadHistory(String userId) async {
    state = const AsyncValue.loading();
    try {
      final history = await _repository.getDonationHistory(userId);
      state = AsyncValue.data(history);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}
