import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/notification_settings_repository_impl.dart';
import '../../domain/entities/notification_settings_entity.dart';
import '../../domain/repositories/notification_settings_repository.dart';

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
  return NotificationSettingsRepositoryImpl();
});

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier,
    AsyncValue<NotificationSettingsEntity>>((ref) {
  final repository = ref.watch(notificationSettingsRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  return NotificationSettingsNotifier(repository, userId);
});

class NotificationSettingsNotifier
    extends StateNotifier<AsyncValue<NotificationSettingsEntity>> {
  final NotificationSettingsRepository _repository;
  final String? _userId;

  NotificationSettingsNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    if (_userId != null) {
      loadSettings();
    }
  }

  Future<void> loadSettings() async {
    if (_userId == null) {
      state =
          const AsyncValue.error('User not authenticated', StackTrace.empty);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final settings = await _repository.getSettings(_userId!);
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleLowStockAlerts(bool value) async {
    if (_userId == null) return;

    final previousState = state;
    state = AsyncValue.data(
      previousState.value!.copyWith(receiveLowStockAlerts: value),
    );

    try {
      final updated = await _repository.updateSettings(
        userId: _userId!,
        receiveLowStockAlerts: value,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = previousState;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSystemNotifications(bool value) async {
    if (_userId == null) return;

    final previousState = state;
    state = AsyncValue.data(
      previousState.value!.copyWith(receiveSystemNotifications: value),
    );

    try {
      final updated = await _repository.updateSettings(
        userId: _userId!,
        receiveSystemNotifications: value,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = previousState;
      state = AsyncValue.error(e, st);
    }
  }
}
