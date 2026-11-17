class AccountVerificationRequestEntity {
  final String id;
  final String donorId;
  final String? username;
  final String? email;
  final String? phone;
  final String? bloodType;
  final String? city;
  final String identityDocumentPath;
  final String medicalDocumentPath;
  final String status;
  final String? adminNote;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const AccountVerificationRequestEntity({
    required this.id,
    required this.donorId,
    this.username,
    this.email,
    this.phone,
    this.bloodType,
    this.city,
    required this.identityDocumentPath,
    required this.medicalDocumentPath,
    required this.status,
    this.adminNote,
    this.reviewedAt,
    required this.createdAt,
  });

  factory AccountVerificationRequestEntity.fromJson(
    Map<String, dynamic> json,
  ) {
    final profile = json['donor'] is Map<String, dynamic>
        ? json['donor'] as Map<String, dynamic>
        : json['profiles'] is Map<String, dynamic>
            ? json['profiles'] as Map<String, dynamic>
            : <String, dynamic>{};

    return AccountVerificationRequestEntity(
      id: json['id']?.toString() ?? '',
      donorId: json['donor_id']?.toString() ?? '',
      username: profile['username']?.toString(),
      email: profile['email']?.toString(),
      phone: profile['phone']?.toString(),
      bloodType: profile['blood_type']?.toString(),
      city: profile['city']?.toString(),
      identityDocumentPath: json['identity_document_path']?.toString() ?? '',
      medicalDocumentPath: json['medical_document_path']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      adminNote: json['admin_note']?.toString(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
}
