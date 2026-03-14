import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/settings_repository.dart';
import 'profile_provider.dart';

final availabilityProvider =
    StateNotifierProvider<AvailabilityNotifier, AsyncValue<bool>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return AvailabilityNotifier(repository);
});

class AvailabilityNotifier extends StateNotifier<AsyncValue<bool>> {
  final SettingsRepository _repository;

  AvailabilityNotifier(this._repository) : super(const AsyncValue.data(false));

  Future<bool> toggle(String userId, bool newValue) async {
    final previousValue = state.value ?? false;
    state = AsyncValue.data(newValue);

    try {
      final success = await _repository.toggleAvailability(
        userId: userId,
        isAvailable: newValue,
      );

      if (!success) {
        state = AsyncValue.data(previousValue);
        return false;
      }
      return true;
    } catch (e) {
      state = AsyncValue.data(previousValue);
      return false;
    }
  }

  void setValue(bool value) {
    state = AsyncValue.data(value);
  }
}
