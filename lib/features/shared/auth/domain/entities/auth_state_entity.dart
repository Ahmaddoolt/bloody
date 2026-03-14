class AuthStateEntity {
  final bool isAuthenticated;
  final bool isLoading;
  final bool hasSeenOnboarding;
  final String? userType;
  final String? errorMessage;
  final bool rememberMe;

  const AuthStateEntity({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.hasSeenOnboarding = false,
    this.userType,
    this.errorMessage,
    this.rememberMe = true,
  });

  bool get isAdmin => userType == 'admin';
  bool get isDonor => userType == 'donor';
  bool get isReceiver => userType == 'receiver';

  AuthStateEntity copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? hasSeenOnboarding,
    String? userType,
    String? errorMessage,
    bool? rememberMe,
    bool clearError = false,
  }) {
    return AuthStateEntity(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      userType: userType ?? this.userType,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
}
