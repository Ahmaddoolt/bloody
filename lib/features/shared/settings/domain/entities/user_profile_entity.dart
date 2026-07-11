class UserProfileEntity {
  final String id;
  final String username;
  final String email;
  final String? phone;
  final String? bloodType;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? birthDate;
  final String userType;
  final bool isAvailable;
  final String? priorityStatus;
  final DateTime? lastDonationDate;
  final String? fcmToken;
  final String? bloodRequestReason;
  final bool isForbidden;
  final String verificationStatus;
  final DateTime? verifiedAt;

  const UserProfileEntity({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.bloodType,
    this.city,
    this.latitude,
    this.longitude,
    this.birthDate,
    required this.userType,
    required this.isAvailable,
    this.priorityStatus,
    this.lastDonationDate,
    this.fcmToken,
    this.bloodRequestReason,
    this.isForbidden = false,
    this.verificationStatus = 'unverified',
    this.verifiedAt,
  });

  bool get isDonor => userType == 'donor';
  bool get isAdmin => userType == 'admin';
  bool get isReceiver => userType == 'receiver';
  bool get isVerified => verificationStatus == 'verified';
  bool get isVerificationPending => verificationStatus == 'pending';

  UserProfileEntity copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? bloodType,
    String? city,
    double? latitude,
    double? longitude,
    String? birthDate,
    String? userType,
    bool? isAvailable,
    String? priorityStatus,
    DateTime? lastDonationDate,
    String? fcmToken,
    String? bloodRequestReason,
    bool? isForbidden,
    String? verificationStatus,
    DateTime? verifiedAt,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bloodType: bloodType ?? this.bloodType,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      birthDate: birthDate ?? this.birthDate,
      userType: userType ?? this.userType,
      isAvailable: isAvailable ?? this.isAvailable,
      priorityStatus: priorityStatus ?? this.priorityStatus,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      fcmToken: fcmToken ?? this.fcmToken,
      bloodRequestReason: bloodRequestReason ?? this.bloodRequestReason,
      isForbidden: isForbidden ?? this.isForbidden,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}
