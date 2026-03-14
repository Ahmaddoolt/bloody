import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/leaderboard_service.dart';

/// Donor model for leaderboard
class LeaderboardDonor {
  final String id;
  final String username;
  final String? email;
  final int points;
  final String? bloodType;
  final String? city;
  final String? phone;

  const LeaderboardDonor({
    required this.id,
    required this.username,
    this.email,
    required this.points,
    this.bloodType,
    this.city,
    this.phone,
  });

  factory LeaderboardDonor.fromJson(Map<String, dynamic> json) {
    return LeaderboardDonor(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      email: json['email']?.toString(),
      points: (json['points'] as num?)?.toInt() ?? 0,
      bloodType: json['blood_type']?.toString(),
      city: json['city']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'points': points,
        'blood_type': bloodType,
        'city': city,
        'phone': phone,
      };
}

/// Leaderboard state
class LeaderboardState {
  final List<LeaderboardDonor> donors;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int totalCount;

  const LeaderboardState({
    this.donors = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.totalCount = 0,
  });

  LeaderboardState copyWith({
    List<LeaderboardDonor>? donors,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? totalCount,
  }) {
    return LeaderboardState(
      donors: donors ?? this.donors,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// Riverpod provider for leaderboard state management
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final _service = LeaderboardService();
  final int _limit = 20;
  int _offset = 0;

  LeaderboardNotifier() : super(const LeaderboardState());

  /// Fetch leaderboard donors with pagination
  Future<void> fetchDonors({bool loadMore = false}) async {
    if (loadMore && (state.isLoadingMore || !state.hasMore)) return;

    state = state.copyWith(
      isLoading: !loadMore,
      isLoadingMore: loadMore,
      error: null,
    );

    if (!loadMore) {
      _offset = 0;
      state = state.copyWith(
        donors: [],
        hasMore: true,
        totalCount: 0,
      );
    }

    try {
      // Fetch donors
      final donorResponse = await _service.fetchTopDonors(
        offset: _offset,
        limit: _limit,
      );

      // Fetch total count on first load
      int totalCount = state.totalCount;
      if (!loadMore) {
        final countResult = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('user_type', 'donor')
            .count();
        totalCount = countResult.count;
      }

      final newDonors =
          donorResponse.map((e) => LeaderboardDonor.fromJson(e)).toList();

      final hasMoreData = newDonors.length >= _limit;

      state = state.copyWith(
        donors: loadMore ? [...state.donors, ...newDonors] : newDonors,
        isLoading: false,
        isLoadingMore: false,
        hasMore: hasMoreData,
        totalCount: totalCount,
      );

      _offset += _limit;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Failed to load leaderboard',
      );
    }
  }

  /// Load more donors (pagination)
  Future<void> loadMore() async {
    await fetchDonors(loadMore: true);
  }

  /// Refresh leaderboard
  Future<void> refresh() async {
    await fetchDonors(loadMore: false);
  }
}

/// Provider for leaderboard state
final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>(
  (ref) => LeaderboardNotifier(),
);

/// Provider for current user's rank (optional - can be fetched separately)
final currentUserRankProvider = FutureProvider<int?>((ref) async {
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  if (currentUserId == null) return null;

  try {
    // This is a simplified rank calculation
    // In production, you might want a dedicated RPC function
    final response = await Supabase.instance.client
        .from('profiles')
        .select('points')
        .eq('id', currentUserId)
        .single();

    final userPoints = (response['points'] as num?)?.toInt() ?? 0;

    // Count how many donors have more points
    final countResponse = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('user_type', 'donor')
        .gt('points', userPoints)
        .count();

    return countResponse.count + 1; // Rank is count + 1
  } catch (e) {
    return null;
  }
});
