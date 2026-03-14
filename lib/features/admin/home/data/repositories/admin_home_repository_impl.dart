import 'package:bloody/core/services/fcm_service.dart';
import 'package:bloody/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/admin_home_entity.dart';
import '../../domain/repositories/admin_home_repository.dart';

class AdminHomeRepositoryImpl implements AdminHomeRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<CenterEntity>> fetchCenters({
    required int limit,
    required int offset,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase.from('centers').select();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }

      final data =
          await query.order('created_at').range(offset, offset + limit - 1);

      return (data as List<dynamic>)
          .map((json) => CenterEntity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error('AdminHomeRepositoryImpl.fetchCenters', e, st);
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> fetchCenterStockTotals() async {
    try {
      final data = await _supabase
          .from('center_inventory')
          .select('center_id, quantity');

      final Map<String, int> totals = {};
      for (final row in data as List<dynamic>) {
        final centerId = row['center_id'].toString();
        final qty = (row['quantity'] as num?)?.toInt() ?? 0;
        totals[centerId] = (totals[centerId] ?? 0) + qty;
      }

      return totals;
    } catch (e, st) {
      AppLogger.error('AdminHomeRepositoryImpl.fetchCenterStockTotals', e, st);
      rethrow;
    }
  }

  @override
  Future<int> fetchPendingPriorityCount() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('id')
          .eq('priority_status', 'pending');

      return (data as List<dynamic>).length;
    } catch (e, st) {
      AppLogger.error(
          'AdminHomeRepositoryImpl.fetchPendingPriorityCount', e, st);
      return 0;
    }
  }

  @override
  Future<void> sendNotificationToDonors({
    required String city,
    String? bloodType,
    String? title,
    String? body,
  }) async {
    await FcmService.notifyDonorsInCity(
      city: city,
      bloodType: bloodType,
      title: title,
      body: body,
    );
  }
}
