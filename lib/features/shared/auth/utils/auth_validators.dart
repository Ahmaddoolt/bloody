import 'package:easy_localization/easy_localization.dart';

class AuthValidators {
  AuthValidators._();

  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'required'.tr();
    if (!_emailRegex.hasMatch(value.trim())) return 'email_invalid'.tr();
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'required'.tr();
    if (value.length < 6) return 'password_error'.tr();
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'required'.tr();
    if (value != password) return 'confirm_password_error'.tr();
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'required'.tr();
    if (value.trim().length < 3) return 'username_error'.tr();
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'phone_required'.tr();
    final digits = value.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 7 || digits.length > 15) return 'phone_invalid'.tr();
    return null;
  }

  /// Returns a strength score from 0.0 to 1.0.
  static double passwordStrength(String password) {
    if (password.isEmpty) return 0.0;
    var score = 0.0;
    if (password.length >= 6) score += 0.2;
    if (password.length >= 10) score += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score += 0.2;
    return score.clamp(0.0, 1.0);
  }
}
