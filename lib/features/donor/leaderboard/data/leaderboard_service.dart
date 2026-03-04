// file: lib/actors/donor/features/leaderboard/data/leaderboard_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/app_logger.dart';

class LeaderboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchTopDonors(
      {required int offset, required int limit}) async {
    AppLogger.info("Fetching Leaderboard offset: $offset, limit: $limit");
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('user_type', 'donor')
          .order('points', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(data);
    } catch (e, stack) {
      AppLogger.error("LeaderboardService.fetchTopDonors", e, stack);
      rethrow;
    }
  }
}
