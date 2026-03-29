import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/priority_repository_impl.dart';
import '../../domain/entities/priority_request_entity.dart';
import '../../domain/repositories/priority_repository.dart';

final priorityRepositoryProvider = Provider<PriorityRepository>((ref) {
  return PriorityRepositoryImpl();
});

final priorityProvider =
    StateNotifierProvider<PriorityNotifier, PriorityState>((ref) {
  final repository = ref.watch(priorityRepositoryProvider);
  return PriorityNotifier(repository);
});

class PriorityNotifier extends StateNotifier<PriorityState> {
  final PriorityRepository _repository;

  PriorityNotifier(this._repository) : super(const PriorityState()) {
    fetchPendingRequests();
  }

  Future<void> fetchPendingRequests() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final requests = await _repository.fetchPendingRequests();
      state = state.copyWith(
        requests: requests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> approveRequest(String userId) async {
    try {
      await _repository.updatePriorityStatus(userId, 'high');
      state = state.copyWith(
        requests: state.requests
            .map((r) => r.id == userId
                ? PriorityRequestEntity(
                    id: r.id,
                    userId: r.userId,
                    username: r.username,
                    phone: r.phone,
                    bloodType: r.bloodType,
                    city: r.city,
                    status: 'high',
                    createdAt: r.createdAt,
                    bloodRequestReason: r.bloodRequestReason,
                    fcmToken: r.fcmToken,
                  )
                : r)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> rejectRequest(String userId) async {
    try {
      await _repository.updatePriorityStatus(userId, 'rejected');
      state = state.copyWith(
        requests: state.requests.where((r) => r.id != userId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> disableRequest(String userId) async {
    try {
      await _repository.updatePriorityStatus(userId, 'none');
      state = state.copyWith(
        requests: state.requests.where((r) => r.id != userId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}
