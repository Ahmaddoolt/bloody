import 'package:bloody/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/priority_request_entity.dart';
import '../../domain/repositories/priority_repository.dart';

class PriorityRepositoryImpl implements PriorityRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<PriorityRequestEntity>> fetchPendingRequests() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('''
            id,
            priority_status,
            created_at,
            username,
            phone,
            blood_type,
            city
          ''')
          .eq('priority_status', 'pending')
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((json) =>
              PriorityRequestEntity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error('PriorityRepositoryImpl.fetchPendingRequests', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updatePriorityStatus(String userId, String status) async {
    try {
      await _supabase
          .from('profiles')
          .update({'priority_status': status}).eq('id', userId);
    } catch (e, st) {
      AppLogger.error('PriorityRepositoryImpl.updatePriorityStatus', e, st);
      rethrow;
    }
  }
}
