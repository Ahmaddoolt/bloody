import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/utils/api_logger.dart';
import '../../data/donor_dashboard_service.dart';

final donorDashboardServiceProvider = Provider<DonorDashboardService>((ref) {
  return DonorDashboardService();
});

/// Provider for donor profile data
final donorProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.read(donorDashboardServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) return null;

  ApiLogger.logResponse(
    method: 'GET',
    endpoint:
        '/rest/v1/profiles?id=eq.$userId&select=blood_type,points,last_donation_date,city',
    statusCode: 200,
    data: {'action': 'Fetching donor profile'},
  );

  return service.getDonorProfile(userId);
});

/// Provider for current user location
final donorLocationProvider = StateProvider<LocationState>((ref) {
  return const LocationState();
});

class LocationState {
  final double? latitude;
  final double? longitude;
  final String? status;
  final bool isLoading;

  const LocationState({
    this.latitude,
    this.longitude,
    this.status,
    this.isLoading = false,
  });

  LocationState copyWith({
    double? latitude,
    double? longitude,
    String? status,
    bool? isLoading,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
