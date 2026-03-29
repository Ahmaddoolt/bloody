import 'package:bloody/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/priority_request_entity.dart';
import '../../domain/repositories/priority_repository.dart';

class PriorityRepositoryImpl implements PriorityRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<PriorityRequestEntity>> fetchPendingRequests() async {
    try {
      final data = await _fetchPendingRequestsData();
      return data
          .map((json) =>
              PriorityRequestEntity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error('PriorityRepositoryImpl.fetchPendingRequests', e, st);
      rethrow;
    }
  }

  Future<List<dynamic>> _fetchPendingRequestsData() async {
    try {
      return await _supabase.from('profiles').select('''
            id,
            priority_status,
            created_at,
            username,
            phone,
            blood_type,
            city,
            blood_request_reason,
            fcm_token
          ''').inFilter('priority_status', [
        'pending',
        'high'
      ]).order('created_at', ascending: false);
    } on PostgrestException catch (error) {
      if (error.code != '42703') rethrow;

      AppLogger.info(
        'PriorityRepositoryImpl.fetchPendingRequests fallback: retrying without optional columns',
      );

      try {
        return await _supabase.from('profiles').select('''
              id,
              priority_status,
              created_at,
              username,
              phone,
              blood_type,
              city,
              fcm_token
            ''').inFilter('priority_status', [
          'pending',
          'high'
        ]).order('created_at', ascending: false);
      } on PostgrestException catch (fallbackError) {
        if (fallbackError.code != '42703') rethrow;

        return await _supabase.from('profiles').select('''
              id,
              priority_status,
              created_at,
              username,
              phone,
              blood_type,
              city
            ''').inFilter('priority_status', [
          'pending',
          'high'
        ]).order('created_at', ascending: false);
      }
    }
  }

  @override
  Future<void> updatePriorityStatus(String userId, String status) async {
    try {
      await _supabase
          .from('profiles')
          .update({'priority_status': status}).eq('id', userId);
      await _notifyUserAboutPriorityStatus(userId, status);
    } catch (e, st) {
      AppLogger.error('PriorityRepositoryImpl.updatePriorityStatus', e, st);
      rethrow;
    }
  }

  Future<void> _notifyUserAboutPriorityStatus(
    String userId,
    String status,
  ) async {
    if (status != 'high' && status != 'none' && status != 'rejected') return;

    try {
      Map<String, dynamic>? profile;
      try {
        profile = await _supabase
            .from('profiles')
            .select('username, fcm_token, language')
            .eq('id', userId)
            .maybeSingle();
      } on PostgrestException catch (error) {
        if (error.code != '42703') rethrow;
        // 'language' column may not exist yet — still fetch fcm_token
        profile = await _supabase
            .from('profiles')
            .select('username, fcm_token')
            .eq('id', userId)
            .maybeSingle();
      }

      final fcmToken = profile?['fcm_token']?.toString();
      final language = profile?['language']?.toString() ?? 'ar';
      final isArabic = language == 'ar';

      final String titleKey;
      final String bodyKey;
      final String pushTitle;
      final String pushBody;

      if (status == 'high') {
        titleKey = 'priority_approved';
        bodyKey = 'priority_approved_desc';
        pushTitle = isArabic ? '🩸 طلب الأولوية مقبول' : '🩸 Priority Approved';
        pushBody = isArabic
            ? 'أنت الآن تظهر بأولوية عالية للمتبرعين.'
            : 'You now appear with high priority to donors.';
      } else if (status == 'rejected') {
        titleKey = 'priority_rejected';
        bodyKey = 'priority_rejected_desc';
        pushTitle = isArabic ? '❌ طلب الأولوية مرفوض' : '❌ Priority Rejected';
        pushBody = isArabic
            ? 'لم تتم الموافقة على طلب أولويتك. يمكنك تقديم طلب جديد.'
            : 'Your priority request was not approved. You may submit a new request.';
      } else {
        // none
        titleKey = 'priority_disabled';
        bodyKey = 'priority_disabled_desc';
        pushTitle = isArabic ? 'تم إيقاف الأولوية' : 'Priority Disabled';
        pushBody = isArabic
            ? 'قام المسؤول بإيقاف حالة الأولوية الخاصة بك.'
            : 'An admin has turned off your priority status.';
      }

      // Edge function handles both the push and the in-app notification insert
      // using service-role key — bypasses RLS entirely.
      try {
        await _supabase.functions.invoke(
          'notify-donors',
          body: {
            if (fcmToken != null && fcmToken.isNotEmpty)
              'tokens': [fcmToken],
            'title': pushTitle,
            'body': pushBody,
            'notification_user_id': userId,
            'notification_title_key': titleKey,
            'notification_body_key': bodyKey,
            'notification_type': 'priority',
          },
        );
      } catch (e) {
        AppLogger.warning(
          'PriorityRepositoryImpl._notifyUserAboutPriorityStatus edge fn failed: $e',
        );
      }
    } catch (e, st) {
      AppLogger.error(
        'PriorityRepositoryImpl._notifyUserAboutPriorityStatus',
        e,
        st,
      );
    }
  }
}
