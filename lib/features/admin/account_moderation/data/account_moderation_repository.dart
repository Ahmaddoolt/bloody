import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_logger.dart';
import '../domain/entities/moderated_user_entity.dart';

class AccountModerationRepository {
  final SupabaseClient _supabase;

  AccountModerationRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<List<ModeratedUserEntity>> fetchUsers({String query = ''}) async {
    try {
      var request = _supabase.from('profiles').select('''
            id,
            username,
            email,
            phone,
            user_type,
            blood_type,
            city,
            is_forbidden,
            forbidden_reason,
            forbidden_at
          ''').neq('email', 'adminbloody2026@gmail.com');

      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        request = request.or(
          'username.ilike.%$trimmed%,email.ilike.%$trimmed%,phone.ilike.%$trimmed%',
        );
      }

      final response =
          await request.order('is_forbidden', ascending: false).limit(80);

      return (response as List<dynamic>)
          .map((json) =>
              ModeratedUserEntity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error('AccountModerationRepository.fetchUsers', e, st);
      rethrow;
    }
  }

  Future<void> banUser({
    required String userId,
    required String reason,
  }) async {
    await _supabase.from('profiles').update({
      'is_forbidden': true,
      'forbidden_reason': reason.trim().isEmpty ? null : reason.trim(),
      'forbidden_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> unbanUser(String userId) async {
    await _supabase.from('profiles').update({
      'is_forbidden': false,
      'forbidden_reason': null,
      'forbidden_at': null,
    }).eq('id', userId);
  }
}
