class UserEntity {
  final String id;
  final String email;
  final String username;
  final String? phone;
  final String userType;
  final String bloodType;
  final String city;
  final DateTime? birthDate;
  final int points;
  final bool isAvailable;
  final double? latitude;
  final double? longitude;
  final String language;

  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    this.phone,
    required this.userType,
    required this.bloodType,
    required this.city,
    this.birthDate,
    this.points = 0,
    this.isAvailable = true,
    this.latitude,
    this.longitude,
    this.language = 'ar',
  });

  bool get isAdmin => email == 'adminbloody2026@gmail.com';
  bool get isDonor => userType == 'donor';
  bool get isReceiver => userType == 'receiver';

  UserEntity copyWith({
    String? id,
    String? email,
    String? username,
    String? phone,
    String? userType,
    String? bloodType,
    String? city,
    DateTime? birthDate,
    int? points,
    bool? isAvailable,
    double? latitude,
    double? longitude,
    String? language,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      bloodType: bloodType ?? this.bloodType,
      city: city ?? this.city,
      birthDate: birthDate ?? this.birthDate,
      points: points ?? this.points,
      isAvailable: isAvailable ?? this.isAvailable,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      language: language ?? this.language,
    );
  }
}
