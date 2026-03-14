import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_state_entity.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStateEntity>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AuthStateEntity> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthStateEntity()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      final hasSeenOnboarding = await _repository.hasSeenOnboarding();
      final rememberMe = await _repository.getRememberMe();
      final sessionResult = await _repository.checkCurrentSession();

      state = state.copyWith(
        isLoading: false,
        hasSeenOnboarding: hasSeenOnboarding,
        rememberMe: rememberMe,
        isAuthenticated: sessionResult?.success ?? false,
        userType: sessionResult?.userType,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.signIn(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userType: result.userType,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error,
      );
    }

    return result;
  }

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
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.signUp(
      email: email,
      password: password,
      username: username,
      phone: phone,
      userType: userType,
      bloodType: bloodType,
      city: city,
      birthDate: birthDate,
    );

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userType: result.userType,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error,
      );
    }

    return result;
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _repository.signOut();
    state = AuthStateEntity(
      hasSeenOnboarding: state.hasSeenOnboarding,
    );
  }

  Future<void> markOnboardingSeen() async {
    await _repository.markOnboardingSeen();
    state = state.copyWith(hasSeenOnboarding: true);
  }

  void setRememberMe(bool value) {
    state = state.copyWith(rememberMe: value);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
