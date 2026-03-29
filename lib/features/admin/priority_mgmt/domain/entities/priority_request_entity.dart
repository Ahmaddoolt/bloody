class PriorityRequestEntity {
  final String id;
  final String userId;
  final String? username;
  final String? phone;
  final String? bloodType;
  final String? city;
  final String status;
  final DateTime? createdAt;
  final String? bloodRequestReason;
  final String? fcmToken;

  const PriorityRequestEntity({
    required this.id,
    required this.userId,
    this.username,
    this.phone,
    this.bloodType,
    this.city,
    required this.status,
    this.createdAt,
    this.bloodRequestReason,
    this.fcmToken,
  });

  factory PriorityRequestEntity.fromJson(Map<String, dynamic> json) {
    // The query fetches flat columns directly from the profiles table.
    return PriorityRequestEntity(
      id: json['id'].toString(),
      userId: json['id']?.toString() ?? '',
      username: json['username']?.toString(),
      phone: json['phone']?.toString(),
      bloodType: json['blood_type']?.toString(),
      city: json['city']?.toString(),
      status: json['priority_status']?.toString() ?? 'none',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      bloodRequestReason: json['blood_request_reason']?.toString(),
      fcmToken: json['fcm_token']?.toString(),
    );
  }
}

class PriorityState {
  final List<PriorityRequestEntity> requests;
  final bool isLoading;
  final String? error;

  const PriorityState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  PriorityState copyWith({
    List<PriorityRequestEntity>? requests,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PriorityState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
