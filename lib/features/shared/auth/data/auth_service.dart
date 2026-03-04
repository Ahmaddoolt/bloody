import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/app_logger.dart';
import '../utils/auth_error_mapper.dart';

class AuthResult {
  final bool success;
  final String? error;
  final User? user;
  final String? userType;

  const AuthResult({
    required this.success,
    this.error,
    this.user,
    this.userType,
  });
}

class AuthService {
  AuthService._();

  static final _supabase = Supabase.instance.client;

  static Future<AuthResult> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe);

      final res = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (res.user == null) {
        return const AuthResult(success: false, error: 'login_failed');
      }

      // Super admin check
      if (email.trim() == 'adminbloody2026@gmail.com') {
        return AuthResult(success: true, user: res.user, userType: 'admin');
      }

      final profile = await _supabase
          .from('profiles')
          .select('user_type')
          .eq('id', res.user!.id)
          .single();

      final userType = profile['user_type'] ?? 'receiver';
      return AuthResult(success: true, user: res.user, userType: userType);
    } catch (e, st) {
      AppLogger.error('AuthService.signIn', e, st);
      return AuthResult(success: false, error: AuthErrorMapper.map(e));
    }
  }

  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
    required String phone,
    required String userType,
    required String bloodType,
    required String city,
    required DateTime birthDate,
  }) async {
    try {
      final position = await _getCurrentLocation();

      final res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      if (res.user == null) {
        return const AuthResult(success: false, error: 'signup_failed');
      }

      await _supabase.from('profiles').insert({
        'id': res.user!.id,
        'email': email.trim(),
        'username': username.trim(),
        'phone': phone.trim(),
        'user_type': userType,
        'blood_type': bloodType,
        'city': city,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'birth_date': birthDate.toIso8601String().split('T')[0],
        'points': 0,
      });

      return AuthResult(success: true, user: res.user, userType: userType);
    } catch (e, st) {
      AppLogger.error('AuthService.signUp', e, st);
      return AuthResult(success: false, error: AuthErrorMapper.map(e));
    }
  }

  static Future<Position?> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }
}
