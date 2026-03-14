import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/api_logger.dart';
import '../../data/donor_dashboard_service.dart';
import 'donor_profile_provider.dart';

/// Provider for receiver list with pagination
final receiverListProvider =
    StateNotifierProvider<ReceiverListNotifier, ReceiverListState>((ref) {
  final service = ref.read(donorDashboardServiceProvider);
  return ReceiverListNotifier(service);
});

class ReceiverListState {
  final List<Map<String, dynamic>> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool hasError;
  final int offset;
  final int limit;
  final int totalCount;

  const ReceiverListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.hasError = false,
    this.offset = 0,
    this.limit = 20,
    this.totalCount = 0,
  });

  ReceiverListState copyWith({
    List<Map<String, dynamic>>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? hasError,
    int? offset,
    int? limit,
    int? totalCount,
  }) {
    return ReceiverListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      hasError: hasError ?? this.hasError,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class ReceiverListNotifier extends StateNotifier<ReceiverListState> {
  final DonorDashboardService _service;

  ReceiverListNotifier(this._service) : super(const ReceiverListState());

  Future<void> fetchReceivers({
    required String donorBloodType,
    String? donorCity,
    double? donorLat,
    double? donorLng,
    bool loadMore = false,
  }) async {
    if (loadMore && (state.isLoadingMore || !state.hasMore)) return;

    // Reset offset to 0 when not loading more (fresh load)
    final currentOffset = loadMore ? state.offset : 0;

    // Set loading state
    state = state.copyWith(
      hasError: false,
      isLoading: loadMore ? false : true,
      isLoadingMore: loadMore ? true : false,
    );

    try {
      // Fetch receivers and total count in parallel for fresh loads
      int totalCount = state.totalCount;
      if (!loadMore) {
        final countFuture =
            _service.getCompatibleReceiversCount(donorBloodType);
        totalCount = await countFuture;
      }

      final receivers = await _service.getCompatibleReceivers(
        donorBloodType: donorBloodType,
        offset: currentOffset,
        limit: state.limit,
        donorCity: donorCity,
        donorLat: donorLat,
        donorLng: donorLng,
      );

      final newItems = loadMore ? [...state.items, ...receivers] : receivers;

      state = state.copyWith(
        items: newItems,
        hasMore: receivers.length >= state.limit,
        offset: currentOffset + state.limit,
        isLoading: false,
        isLoadingMore: false,
        totalCount: totalCount,
      );

      ApiLogger.logResponse(
        method: 'GET',
        endpoint: '/rest/v1/profiles?user_type=eq.receiver',
        statusCode: 200,
        data: {
          'count': receivers.length,
          'total_loaded': newItems.length,
          'total_count': totalCount
        },
      );
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        isLoading: false,
        isLoadingMore: false,
      );

      ApiLogger.logError(
        method: 'GET',
        endpoint: '/rest/v1/profiles?user_type=eq.receiver',
        error: e,
      );
    }
  }

  void refresh() {
    state = const ReceiverListState();
  }

  void clear() {
    state = const ReceiverListState();
  }
}
