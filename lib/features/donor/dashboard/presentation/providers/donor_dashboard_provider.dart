import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'deferral_timer_provider.dart';
import 'donor_profile_provider.dart';
import 'receiver_list_provider.dart';

/// Provider for view mode (list vs map)
final isMapViewProvider = StateProvider<bool>((ref) => false);

/// Provider for markers on the map
final mapMarkersProvider = StateProvider<Set<dynamic>>((ref) => {});

/// Provider for auto-refresh functionality
final autoRefreshProvider = Provider<AutoRefreshController>((ref) {
  return AutoRefreshController(ref);
});

class AutoRefreshController {
  final Ref _ref;
  Timer? _timer;

  AutoRefreshController(this._ref);

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      final deferralState = _ref.read(deferralTimerProvider);
      final receiverState = _ref.read(receiverListProvider);

      // Only refresh if not deferred and not already loading
      if (!deferralState.isDeferred && !receiverState.isLoading) {
        _refreshData();
      }
    });
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _refreshData() async {
    final profileAsync = _ref.read(donorProfileProvider);
    final location = _ref.read(donorLocationNotifierProvider);

    profileAsync.whenOrNull(
      data: (profile) {
        if (profile != null) {
          final bloodType = profile['blood_type'] as String?;
          if (bloodType != null) {
            _ref.read(receiverListProvider.notifier).fetchReceivers(
                  donorBloodType: bloodType,
                  donorCity: profile['city'] as String?,
                  donorLat: location.latitude,
                  donorLng: location.longitude,
                  loadMore: false,
                );
          }
        }
      },
    );
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Provider for donor location with geolocation
final donorLocationNotifierProvider =
    StateNotifierProvider<DonorLocationNotifier, LocationState>((ref) {
  return DonorLocationNotifier();
});

class DonorLocationNotifier extends StateNotifier<LocationState> {
  DonorLocationNotifier() : super(const LocationState());

  Future<void> determinePosition() async {
    state = state.copyWith(isLoading: true, status: 'checking_location');

    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          status: 'location_denied',
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      state = state.copyWith(
        latitude: pos.latitude,
        longitude: pos.longitude,
        isLoading: false,
        status: '',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        status: 'gps_unavailable',
      );
    }
  }
}
