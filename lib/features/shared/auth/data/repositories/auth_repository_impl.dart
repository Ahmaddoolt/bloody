import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/api_logger.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../utils/auth_error_mapper.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final _supabase = Supabase.instance.client;
  UserEntity? _currentUser;

  @override
  UserEntity? get currentUser => _currentUser;

  @override
  Future<AuthResult> signIn({
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
        ApiLogger.logError(
          method: 'POST',
          endpoint: '/auth/v1/token',
          error: 'User is null after sign in',
          statusCode: 401,
        );
        return AuthResult.failure('login_failed');
      }

      ApiLogger.logResponse(
        method: 'POST',
        endpoint: '/auth/v1/token',
        statusCode: 200,
        data: {
          'user_id': res.user!.id,
          'email': res.user!.email,
          'created_at': res.user!.createdAt,
        },
      );

      if (email.trim() == 'adminbloody2026@gmail.com') {
        _currentUser = UserEntity(
          id: res.user!.id,
          email: email.trim(),
          username: 'Admin',
          userType: 'admin',
          bloodType: 'O+',
          city: 'Damascus',
        );
        return AuthResult.success(user: _currentUser, userType: 'admin');
      }

      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', res.user!.id)
          .single();

      ApiLogger.logResponse(
        method: 'GET',
        endpoint: '/rest/v1/profiles?id=eq.${res.user!.id}',
        statusCode: 200,
        data: profile,
      );

      _currentUser = _mapProfileToUser(res.user!.id, profile);
      return AuthResult.success(
        user: _currentUser,
        userType: profile['user_type'] ?? 'receiver',
      );
    } catch (e, st) {
      AppLogger.error('AuthRepositoryImpl.signIn', e, st);
      ApiLogger.logError(
        method: 'POST',
        endpoint: '/auth/v1/token',
        error: e,
        statusCode: e is AuthException
            ? int.tryParse(e.statusCode?.toString() ?? '')
            : null,
      );
      return AuthResult.failure(AuthErrorMapper.map(e));
    }
  }

  @override
  Future<AuthResult> signUp({
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
        ApiLogger.logError(
          method: 'POST',
          endpoint: '/auth/v1/signup',
          error: 'User is null after sign up',
          statusCode: 400,
        );
        return AuthResult.failure('signup_failed');
      }

      ApiLogger.logResponse(
        method: 'POST',
        endpoint: '/auth/v1/signup',
        statusCode: 200,
        data: {
          'user_id': res.user!.id,
          'email': res.user!.email,
          'user_type': userType,
        },
      );

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
        'is_available': true,
      });

      ApiLogger.logResponse(
        method: 'POST',
        endpoint: '/rest/v1/profiles',
        statusCode: 201,
        data: {
          'id': res.user!.id,
          'username': username.trim(),
          'user_type': userType,
          'city': city,
        },
      );

      _currentUser = UserEntity(
        id: res.user!.id,
        email: email.trim(),
        username: username.trim(),
        phone: phone.trim(),
        userType: userType,
        bloodType: bloodType,
        city: city,
        birthDate: birthDate,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      return AuthResult.success(user: _currentUser, userType: userType);
    } catch (e, st) {
      AppLogger.error('AuthRepositoryImpl.signUp', e, st);
      ApiLogger.logError(
        method: 'POST',
        endpoint: '/auth/v1/signup',
        error: e,
        statusCode: e is AuthException
            ? int.tryParse(e.statusCode?.toString() ?? '')
            : null,
      );
      return AuthResult.failure(AuthErrorMapper.map(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      ApiLogger.logResponse(
        method: 'POST',
        endpoint: '/auth/v1/logout',
        statusCode: 200,
        data: {'message': 'User signed out successfully'},
      );
    } catch (e, st) {
      AppLogger.error('AuthRepositoryImpl.signOut', e, st);
      ApiLogger.logError(
        method: 'POST',
        endpoint: '/auth/v1/logout',
        error: e,
      );
    }
  }

  @override
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seen_onboarding') ?? false;
  }

  @override
  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
  }

  @override
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember_me') ?? true;
  }

  @override
  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
  }

  @override
  Future<AuthResult?> checkCurrentSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        _currentUser = null;
        ApiLogger.logResponse(
          method: 'GET',
          endpoint: '/auth/v1/session',
          statusCode: 401,
          data: {'message': 'No active session'},
        );
        return null;
      }

      ApiLogger.logResponse(
        method: 'GET',
        endpoint: '/auth/v1/session',
        statusCode: 200,
        data: {
          'user_id': session.user.id,
          'email': session.user.email,
          'expires_at': session.expiresAt,
        },
      );

      final rememberMe = await getRememberMe();
      if (!rememberMe) {
        await _supabase.auth.signOut();
        _currentUser = null;
        ApiLogger.logResponse(
          method: 'POST',
          endpoint: '/auth/v1/logout',
          statusCode: 200,
          data: {'message': 'Session expired (remember_me=false)'},
        );
        return null;
      }

      if (session.user.email == 'adminbloody2026@gmail.com') {
        _currentUser = UserEntity(
          id: session.user.id,
          email: session.user.email!,
          username: 'Admin',
          userType: 'admin',
          bloodType: 'O+',
          city: 'Damascus',
        );
        return AuthResult.success(user: _currentUser, userType: 'admin');
      }

      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .single();

      ApiLogger.logResponse(
        method: 'GET',
        endpoint: '/rest/v1/profiles?id=eq.${session.user.id}',
        statusCode: 200,
        data: profile,
      );

      _currentUser = _mapProfileToUser(session.user.id, profile);
      return AuthResult.success(
        user: _currentUser,
        userType: profile['user_type'] ?? 'receiver',
      );
    } catch (e, st) {
      AppLogger.error('AuthRepositoryImpl.checkCurrentSession', e, st);
      ApiLogger.logError(
        method: 'GET',
        endpoint: '/auth/v1/session',
        error: e,
      );
      _currentUser = null;
      return null;
    }
  }

  Future<Position?> _getCurrentLocation() async {
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

  UserEntity _mapProfileToUser(String id, Map<String, dynamic> profile) {
    return UserEntity(
      id: id,
      email: profile['email'] ?? '',
      username: profile['username'] ?? '',
      phone: profile['phone'],
      userType: profile['user_type'] ?? 'receiver',
      bloodType: profile['blood_type'] ?? 'O+',
      city: profile['city'] ?? 'Damascus',
      points: profile['points'] ?? 0,
      isAvailable: profile['is_available'] ?? true,
      latitude: profile['latitude']?.toDouble(),
      longitude: profile['longitude']?.toDouble(),
      language: profile['language'] ?? 'ar',
    );
  }
}
