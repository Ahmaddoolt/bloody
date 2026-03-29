class UserProfileEntity {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String? bloodType;
  final String? city;
  final String? birthDate;
  final String userType;
  final bool isAvailable;
  final String? priorityStatus;
  final DateTime? lastDonationDate;
  final String? fcmToken;
  final String? bloodRequestReason;

  const UserProfileEntity({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.bloodType,
    this.city,
    this.birthDate,
    required this.userType,
    required this.isAvailable,
    this.priorityStatus,
    this.lastDonationDate,
    this.fcmToken,
    this.bloodRequestReason,
  });

  bool get isDonor => userType == 'donor';
  bool get isAdmin => userType == 'admin';
  bool get isReceiver => userType == 'receiver';

  UserProfileEntity copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? bloodType,
    String? city,
    String? birthDate,
    String? userType,
    bool? isAvailable,
    String? priorityStatus,
    DateTime? lastDonationDate,
    String? fcmToken,
    String? bloodRequestReason,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bloodType: bloodType ?? this.bloodType,
      city: city ?? this.city,
      birthDate: birthDate ?? this.birthDate,
      userType: userType ?? this.userType,
      isAvailable: isAvailable ?? this.isAvailable,
      priorityStatus: priorityStatus ?? this.priorityStatus,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      fcmToken: fcmToken ?? this.fcmToken,
      bloodRequestReason: bloodRequestReason ?? this.bloodRequestReason,
    );
  }
}
