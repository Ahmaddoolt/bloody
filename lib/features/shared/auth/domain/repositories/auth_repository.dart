import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<AuthResult> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
    required String phone,
    required String userType,
    required String bloodType,
    required String city,
    required DateTime birthDate,
  });

  Future<void> signOut();

  Future<bool> hasSeenOnboarding();
  Future<void> markOnboardingSeen();

  Future<bool> getRememberMe();
  Future<void> setRememberMe(bool value);

  Future<AuthResult?> checkCurrentSession();

  UserEntity? get currentUser;
}

class AuthResult {
  final bool success;
  final String? error;
  final UserEntity? user;
  final String? userType;

  const AuthResult({
    required this.success,
    this.error,
    this.user,
    this.userType,
  });

  factory AuthResult.success({UserEntity? user, String? userType}) =>
      AuthResult(success: true, user: user, userType: userType);

  factory AuthResult.failure(String error) =>
      AuthResult(success: false, error: error);
}
