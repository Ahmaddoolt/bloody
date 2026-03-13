// file: lib/core/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _supabase = Supabase.instance.client;

  /// Requests notification permission, retrieves the FCM token, saves it to
  /// the current user's profile, and subscribes to token refresh events.
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
          .update({'fcm_token': token})
          .eq('id', userId);
    } catch (e) {
      AppLogger.error('FcmService._saveToken', e);
    }
  }

  /// Calls the `notify-donors` Edge Function to push a notification to all
  /// available donors in [city].
  static Future<void> notifyDonorsInCity({
    required String city,
    required String title,
    required String body,
  }) async {
    try {
      await _supabase.functions.invoke(
        'notify-donors',
        body: {'city': city, 'title': title, 'body': body},
      );
    } catch (e, st) {
      AppLogger.error('FcmService.notifyDonorsInCity ERROR', e, st);
    }
  }

  /// Listens for foreground FCM messages and inserts them into the
  /// `notifications` table so they appear in the in-app notification screen.
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
}
