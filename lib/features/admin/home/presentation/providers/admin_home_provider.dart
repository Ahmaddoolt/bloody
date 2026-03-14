import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/admin_home_repository_impl.dart';
import '../../domain/entities/admin_home_entity.dart';
import '../../domain/repositories/admin_home_repository.dart';

final adminHomeRepositoryProvider = Provider<AdminHomeRepository>((ref) {
  return AdminHomeRepositoryImpl();
});

final adminHomeProvider =
    StateNotifierProvider<AdminHomeNotifier, AdminHomeState>((ref) {
  final repository = ref.watch(adminHomeRepositoryProvider);
  return AdminHomeNotifier(repository);
});

class AdminHomeNotifier extends StateNotifier<AdminHomeState> {
  final AdminHomeRepository _repository;
  static const int _limit = 20;
  int _offset = 0;

  AdminHomeNotifier(this._repository) : super(const AdminHomeState()) {
    fetchCenters();
    fetchPendingPriorityCount();
  }

  Future<void> fetchCenters({bool loadMore = false}) async {
    if (loadMore && (state.isLoadingMore || !state.hasMore)) return;

    state = state.copyWith(
      isLoading: !loadMore,
      isLoadingMore: loadMore,
      clearError: true,
    );

    if (!loadMore) {
      _offset = 0;
      state =
          state.copyWith(centers: [], hasMore: true, isSortedByStock: false);
    }

    try {
      final centers = await _repository.fetchCenters(
        limit: _limit,
        offset: _offset,
        searchQuery: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      state = state.copyWith(
        centers: loadMore ? [...state.centers, ...centers] : centers,
        isLoading: false,
        isLoadingMore: false,
        hasMore: centers.length < _limit ? false : state.hasMore,
      );

      _offset += _limit;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sortCentersByStock() async {
    if (state.isSortingByStock) return;

    state = state.copyWith(isSortingByStock: true);

    try {
      final totals = await _repository.fetchCenterStockTotals();

      final sorted = List<CenterEntity>.from(state.centers)
        ..sort((a, b) {
          final aTotal = totals[a.id] ?? 0;
          final bTotal = totals[b.id] ?? 0;
          return aTotal.compareTo(bTotal);
        });

      state = state.copyWith(
        centers: sorted,
        isSortedByStock: true,
        isSortingByStock: false,
      );
    } catch (e) {
      state = state.copyWith(isSortingByStock: false);
    }
  }

  Future<void> fetchPendingPriorityCount() async {
    try {
      final count = await _repository.fetchPendingPriorityCount();
      state = state.copyWith(pendingPriorityCount: count);
    } catch (_) {}
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    _offset = 0;
    await fetchCenters(loadMore: false);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    _offset = 0;
    fetchCenters(loadMore: false);
  }

  Future<void> sendNotification({
    required String city,
    String? bloodType,
    String? title,
    String? body,
  }) async {
    await _repository.sendNotificationToDonors(
      city: city,
      bloodType: bloodType,
      title: title,
      body: body,
    );
  }
}
