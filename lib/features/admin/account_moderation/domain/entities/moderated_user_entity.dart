class ModeratedUserEntity {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String userType;
  final String? bloodType;
  final String? city;
  final bool isForbidden;
  final String? forbiddenReason;
  final DateTime? forbiddenAt;

  const ModeratedUserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    required this.userType,
    this.bloodType,
    this.city,
    required this.isForbidden,
    this.forbiddenReason,
    this.forbiddenAt,
  });

  factory ModeratedUserEntity.fromJson(Map<String, dynamic> json) {
    return ModeratedUserEntity(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      userType: json['user_type']?.toString() ?? 'receiver',
      bloodType: json['blood_type']?.toString(),
      city: json['city']?.toString(),
      isForbidden: json['is_forbidden'] == true,
      forbiddenReason: json['forbidden_reason']?.toString(),
      forbiddenAt: json['forbidden_at'] != null
          ? DateTime.tryParse(json['forbidden_at'].toString())
          : null,
    );
  }
}
