class PriorityRequestEntity {
  final String id;
  final String userId;
  final String? username;
  final String? phone;
  final String? bloodType;
  final String? city;
  final String status;
  final DateTime? createdAt;

  const PriorityRequestEntity({
    required this.id,
    required this.userId,
    this.username,
    this.phone,
    this.bloodType,
    this.city,
    required this.status,
    this.createdAt,
  });

  factory PriorityRequestEntity.fromJson(Map<String, dynamic> json) {
    return PriorityRequestEntity(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      username: json['profiles']?['username'],
      phone: json['profiles']?['phone'],
      bloodType: json['profiles']?['blood_type'],
      city: json['profiles']?['city'],
      status: json['priority_status'] ?? 'none',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
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
