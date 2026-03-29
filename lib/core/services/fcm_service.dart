import 'package:bloody/core/notifications/notification_templates.dart';
import 'package:bloody/core/utils/app_logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'background_message_handler.dart';

abstract class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  static SupabaseClient get _supabase => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token);

      _messaging.onTokenRefresh.listen((newToken) async {
        await _saveToken(newToken);
      });
    } catch (e) {
      AppLogger.error('FcmService.initialize', e);
    }
  }

  static Future<void> _saveToken(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('profiles')
          .update({'fcm_token': token}).eq('id', userId);
    } catch (e) {
      AppLogger.error('FcmService._saveToken', e);
    }
  }

  static Future<bool> _ensureValidSession() async {
    try {
      final session = _supabase.auth.currentSession;

      if (session == null) {
        AppLogger.error(
          'FcmService._ensureValidSession',
          'No session found',
          StackTrace.current,
        );
        return false;
      }

      if (session.isExpired) {
        AppLogger.info('Session expired, attempting refresh...');
        final refreshed = await _supabase.auth.refreshSession();
        if (refreshed.session == null) {
          AppLogger.error(
            'FcmService._ensureValidSession',
            'Session refresh failed',
            StackTrace.current,
          );
          return false;
        }
      }

      return true;
    } catch (e, st) {
      AppLogger.error('FcmService._ensureValidSession', e, st);
      return false;
    }
  }

  static Future<bool> notifyDonorsInCity({
    required String city,
    String? bloodType,
    String? title,
    String? body,
    String type = 'blood_request',
  }) async {
    try {
      final sessionValid = await _ensureValidSession();
      if (!sessionValid) {
        AppLogger.error(
          'FcmService.notifyDonorsInCity',
          'Invalid or expired session. Please log in again.',
          StackTrace.current,
        );
        return false;
      }

      final notificationTitle = title ??
          NotificationTemplates.getTitle(
            type,
            NotificationTemplates.defaultLanguage,
            params: {'city': city, 'blood_type': bloodType ?? ''},
          );
      final notificationBody = body ??
          NotificationTemplates.getBody(
            type,
            NotificationTemplates.defaultLanguage,
            params: {'city': city, 'blood_type': bloodType ?? ''},
          );

      await _supabase.functions.invoke(
        'notify-donors',
        body: {
          'city': city,
          'title': notificationTitle,
          'body': notificationBody,
          'blood_type': bloodType,
          'type': type,
        },
      );
      return true;
    } catch (e, st) {
      AppLogger.error('FcmService.notifyDonorsInCity', e, st);
      return false;
    }
  }

  static Future<bool> notifyDonorsInCityLocalized({
    required String city,
    required String bloodType,
    String type = 'blood_request',
  }) async {
    try {
      final sessionValid = await _ensureValidSession();
      if (!sessionValid) {
        AppLogger.error(
          'FcmService.notifyDonorsInCityLocalized',
          'Invalid or expired session. Please log in again.',
          StackTrace.current,
        );
        return false;
      }

      final donors = await _supabase
          .from('profiles')
          .select(
            'fcm_token, language, notification_settings!inner(receive_low_stock_alerts, receive_system_notifications)',
          )
          .eq('user_type', 'donor')
          .eq('city', city)
          .eq('is_available', true)
          .not('fcm_token', 'is', null);

      if (donors.isEmpty) return true;

      final tokensByLanguage = <String, List<String>>{};
      for (final donor in donors) {
        final token = donor['fcm_token'] as String?;
        final language = donor['language'] as String? ??
            NotificationTemplates.defaultLanguage;
        if (token == null) continue;

        // Respect notification settings
        final settings = donor['notification_settings'] as Map<String, dynamic>?;
        if (settings != null) {
          if (type == 'low_stock' && settings['receive_low_stock_alerts'] == false) continue;
          if (type != 'low_stock' && settings['receive_system_notifications'] == false) continue;
        }

        tokensByLanguage.putIfAbsent(language, () => []).add(token);
      }

      final projectId = await _getFirebaseProjectId();
      final accessToken = await _getAccessToken();
      final fcmUrl =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      for (final entry in tokensByLanguage.entries) {
        final language = entry.key;
        final tokens = entry.value;
        final notification = NotificationTemplates.getNotification(
          type,
          language,
          params: {'city': _translateCity(city, language), 'blood_type': bloodType},
        );

        for (final token in tokens) {
          await _sendFcmMessage(fcmUrl, accessToken, token, notification);
        }
      }

      return true;
    } catch (e, st) {
      AppLogger.error('FcmService.notifyDonorsInCityLocalized', e, st);
      return false;
    }
  }

  static String _translateCity(String city, String language) {
    if (language != 'ar') return city;
    const translations = {
      'Damascus': 'دمشق',
      'Aleppo': 'حلب',
      'Homs': 'حمص',
      'Hama': 'حماة',
      'Latakia': 'اللاذقية',
      'Tartus': 'طرطوس',
      'Idlib': 'إدلب',
      'Daraa': 'درعا',
      'As-Suwayda': 'السويداء',
      'Quneitra': 'القنيطرة',
      'Deir ez-Zor': 'دير الزور',
      'Al-Hasakah': 'الحسكة',
      'Raqqa': 'الرقة',
      'Rif Dimashq': 'ريف دمشق',
    };
    return translations[city] ?? city;
  }

  static Future<void> _sendFcmMessage(
    String fcmUrl,
    String accessToken,
    String token,
    Map<String, String> notification,
  ) async {
    await _supabase.functions.invoke(
      'send-fcm',
      body: {
        'token': token,
        'title': notification['title'],
        'body': notification['body'],
      },
    );
  }

  static Future<String> _getFirebaseProjectId() async {
    return 'bookapp-2cf1b';
  }

  static Future<String> _getAccessToken() async {
    final b64 = await _getFirebaseServiceAccountB64();
    final json = _parseB64(b64);
    return _createAccessToken(json);
  }

  static Future<String> _getFirebaseServiceAccountB64() async {
    final response = await _supabase
        .from('app_config')
        .select('value')
        .eq('key', 'firebase_service_account_b64')
        .single();
    return response['value'] as String;
  }

  static Map<String, dynamic> _parseB64(String b64) {
    final jsonString = String.fromCharCodes(
      b64.codeUnits.map((c) => c - 1),
    );
    return Map<String, dynamic>.from(
      jsonString.split('').fold<Map<String, dynamic>>(
        {},
        (map, char) => map,
      ),
    );
  }

  static Future<String> _createAccessToken(Map<String, dynamic> json) async {
    return 'mock_access_token';
  }

  static void setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId == null) return;

        final notification = message.notification;
        if (notification == null) return;

        await _supabase.from('notifications').insert({
          'user_id': userId,
          'title': notification.title ?? '',
          'body': notification.body ?? '',
          'is_read': false,
        });
      } catch (e) {
        AppLogger.error('FcmService.setupForegroundHandler', e);
      }
    });
  }

  static void setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}
