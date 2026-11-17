import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account_moderation_repository.dart';
import '../../domain/entities/moderated_user_entity.dart';

final accountModerationRepositoryProvider =
    Provider<AccountModerationRepository>((ref) {
  return AccountModerationRepository();
});

final accountModerationProvider = StateNotifierProvider<
    AccountModerationNotifier, AsyncValue<List<ModeratedUserEntity>>>((ref) {
  return AccountModerationNotifier(
    ref.watch(accountModerationRepositoryProvider),
  );
});

class AccountModerationNotifier
    extends StateNotifier<AsyncValue<List<ModeratedUserEntity>>> {
  final AccountModerationRepository _repository;
  String _query = '';

  AccountModerationNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch({String? query}) async {
    if (query != null) _query = query;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.fetchUsers(query: _query));
  }

  Future<bool> ban({
    required String userId,
    required String reason,
  }) async {
    try {
      await _repository.banUser(userId: userId, reason: reason);
      await fetch();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> unban(String userId) async {
    try {
      await _repository.unbanUser(userId);
      await fetch();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}
