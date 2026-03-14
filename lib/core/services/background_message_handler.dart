import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseMessaging.instance.getInitialMessage();

  final notification = message.notification;
  if (notification == null) return;

  final data = message.data;
  final userId = data['user_id'];

  if (userId == null) return;

  try {
    await Supabase.instance.client.from('notifications').insert({
      'user_id': userId,
      'title': notification.title ?? '',
      'body': notification.body ?? '',
      'type': data['type'] ?? 'system',
      'is_read': false,
    });
  } catch (_) {}
}
