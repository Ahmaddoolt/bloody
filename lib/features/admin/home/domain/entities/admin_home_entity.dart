class CenterEntity {
  final String id;
  final String name;
  final String city;
  final String address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? email;
  final DateTime createdAt;

  const CenterEntity({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.email,
    required this.createdAt,
  });

  factory CenterEntity.fromJson(Map<String, dynamic> json) {
    return CenterEntity(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      email: json['email'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'city': city,
        'address': address,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'email': email,
        'created_at': createdAt.toIso8601String(),
      };
}

class AdminHomeState {
  final List<CenterEntity> centers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isSortedByStock;
  final bool isSortingByStock;
  final int pendingPriorityCount;
  final String searchQuery;
  final String? error;

  const AdminHomeState({
    this.centers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.isSortedByStock = false,
    this.isSortingByStock = false,
    this.pendingPriorityCount = 0,
    this.searchQuery = '',
    this.error,
  });

  AdminHomeState copyWith({
    List<CenterEntity>? centers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? isSortedByStock,
    bool? isSortingByStock,
    int? pendingPriorityCount,
    String? searchQuery,
    String? error,
    bool clearError = false,
  }) {
    return AdminHomeState(
      centers: centers ?? this.centers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      isSortedByStock: isSortedByStock ?? this.isSortedByStock,
      isSortingByStock: isSortingByStock ?? this.isSortingByStock,
      pendingPriorityCount: pendingPriorityCount ?? this.pendingPriorityCount,
      searchQuery: searchQuery ?? this.searchQuery,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
