import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthErrorMapper {
  AuthErrorMapper._();

  static String map(Object error) {
    if (error is AuthException) {
      return _mapAuthMessage(error.message);
    }
    final msg = error.toString().toLowerCase();
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('connection')) {
      return 'auth_error_network'.tr();
    }
    return 'login_failed'.tr();
  }

  static String _mapAuthMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'auth_error_invalid_credentials'.tr();
    }
    if (lower.contains('email not confirmed')) {
      return 'auth_error_email_not_confirmed'.tr();
    }
    if (lower.contains('already registered') ||
        lower.contains('already been registered') ||
        lower.contains('user_already_exists')) {
      return 'auth_error_already_registered'.tr();
    }
    if (lower.contains('too many requests') || lower.contains('rate limit')) {
      return 'auth_error_too_many_requests'.tr();
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'auth_error_network'.tr();
    }
    return 'login_failed'.tr();
  }
}
