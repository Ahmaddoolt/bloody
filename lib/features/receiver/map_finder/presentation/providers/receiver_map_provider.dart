import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../core/utils/app_logger.dart';
import '../../../../../../core/utils/map_marker_helper.dart';
import '../../data/map_finder_service.dart';

const _syrianCityCoordinates = <String, LatLng>{
  'Damascus': LatLng(33.5138, 36.2765),
  'Aleppo': LatLng(36.2021, 37.1343),
  'Homs': LatLng(34.7324, 36.7137),
  'Hama': LatLng(35.1318, 36.7551),
  'Latakia': LatLng(35.5317, 35.7917),
  'Tartus': LatLng(34.8959, 35.8866),
  'Idlib': LatLng(35.9306, 36.6339),
  'Daraa': LatLng(32.6189, 36.1021),
  'As-Suwayda': LatLng(32.7086, 36.5661),
  'Quneitra': LatLng(33.1261, 35.8243),
  'Deir ez-Zor': LatLng(35.3354, 40.1407),
  'Al-Hasakah': LatLng(36.4844, 40.7489),
  'Raqqa': LatLng(35.9500, 39.0100),
  'Rif Dimashq': LatLng(33.5500, 36.4500),
};

const receiverBloodTypes = <String>[
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];

final mapFinderServiceProvider = Provider<MapFinderService>((ref) {
  return MapFinderService();
});

final donorMarkerIconProvider = FutureProvider<BitmapDescriptor>((ref) async {
  return MapMarkerHelper.getDonorMarker();
});

final receiverMapProvider =
    StateNotifierProvider<ReceiverMapNotifier, ReceiverMapState>((ref) {
  final service = ref.read(mapFinderServiceProvider);
  return ReceiverMapNotifier(service);
});

class ReceiverMapState {
  final bool isMapView;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool hasError;
  final bool isConfirmingDonation;
  final List<Map<String, dynamic>> donors;
  final int limit;
  final int offset;
  final Position? currentPosition;
  final LatLng? fallbackLatLng;
  final String statusKey;
  final String? neededBloodType;
  final String? city;
  final String? bloodRequestReason;

  const ReceiverMapState({
    this.isMapView = false,
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.hasError = false,
    this.isConfirmingDonation = false,
    this.donors = const [],
    this.limit = 50,
    this.offset = 0,
    this.currentPosition,
    this.fallbackLatLng,
    this.statusKey = '',
    this.neededBloodType,
    this.city,
    this.bloodRequestReason,
  });

  ReceiverMapState copyWith({
    bool? isMapView,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? hasError,
    bool? isConfirmingDonation,
    List<Map<String, dynamic>>? donors,
    int? limit,
    int? offset,
    Position? currentPosition,
    LatLng? fallbackLatLng,
    String? statusKey,
    String? neededBloodType,
    String? city,
    String? bloodRequestReason,
  }) {
    return ReceiverMapState(
      isMapView: isMapView ?? this.isMapView,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      hasError: hasError ?? this.hasError,
      isConfirmingDonation:
          isConfirmingDonation ?? this.isConfirmingDonation,
      donors: donors ?? this.donors,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      currentPosition: currentPosition ?? this.currentPosition,
      fallbackLatLng: fallbackLatLng ?? this.fallbackLatLng,
      statusKey: statusKey ?? this.statusKey,
      neededBloodType: neededBloodType ?? this.neededBloodType,
      city: city ?? this.city,
      bloodRequestReason: bloodRequestReason ?? this.bloodRequestReason,
    );
  }
}

class ReceiverMapNotifier extends StateNotifier<ReceiverMapState> {
  final MapFinderService _service;

  Timer? _autoRefreshTimer;
  bool _isInitialized = false;

  ReceiverMapNotifier(this._service) : super(const ReceiverMapState());

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await determinePosition();
    await _fetchInitialProfile();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (state.neededBloodType == null ||
          state.isInitialLoading ||
          state.isLoadingMore) {
        return;
      }

      unawaited(fetchDonors(loadMore: false));
    });
  }

  Future<void> retryLocation() async {
    await determinePosition();
    if (state.neededBloodType != null) {
      await fetchDonors(loadMore: false);
    }
  }

  Future<void> determinePosition() async {
    state = state.copyWith(statusKey: 'checking_location');

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Fall back to city coordinates instead of blocking the map
        final cityLatLng = _syrianCityCoordinates[state.city];
        state = state.copyWith(
          fallbackLatLng: cityLatLng,
          statusKey: '',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      state = state.copyWith(currentPosition: position, statusKey: '');
    } catch (error, stackTrace) {
      AppLogger.error(
        'ReceiverMapNotifier.determinePosition',
        error,
        stackTrace,
      );

      try {
        final lastKnownPosition = await Geolocator.getLastKnownPosition();
        if (lastKnownPosition != null) {
          state = state.copyWith(
            currentPosition: lastKnownPosition,
            statusKey: '',
          );
          return;
        }
      } catch (fallbackError, fallbackStackTrace) {
        AppLogger.error(
          'ReceiverMapNotifier.getLastKnownPosition',
          fallbackError,
          fallbackStackTrace,
        );
      }

      // Fall back to city coordinates
      final cityLatLng = _syrianCityCoordinates[state.city];
      state = state.copyWith(
        fallbackLatLng: cityLatLng,
        statusKey: '',
      );
    }
  }

  Future<void> selectBloodType(String bloodType) async {
    if (state.neededBloodType == bloodType && state.donors.isNotEmpty) return;

    state = state.copyWith(neededBloodType: bloodType);
    await fetchDonors(loadMore: false);
  }

  void toggleMapView() {
    state = state.copyWith(isMapView: !state.isMapView);
  }

  Future<void> refresh() async {
    await fetchDonors(loadMore: false);
  }

  Future<void> loadMore() async {
    await fetchDonors(loadMore: true);
  }

  Future<bool> confirmDonation(String donorId) async {
    if (state.isConfirmingDonation) return false;

    state = state.copyWith(isConfirmingDonation: true);
    try {
      final success = await _service.confirmDonation(donorId);
      if (success) {
        await fetchDonors(loadMore: false);
      }
      return success;
    } finally {
      state = state.copyWith(isConfirmingDonation: false);
    }
  }

  Future<void> _fetchInitialProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(isInitialLoading: false, hasError: true);
      return;
    }

    try {
      final profile = await _service.getReceiverProfile(userId);
      if (profile == null) {
        state = state.copyWith(isInitialLoading: false, hasError: true);
        return;
      }

      final neededBloodType = _normalizeBloodType(profile['blood_type'] as String?);
      final city = profile['city'] as String?;
      final bloodRequestReason = profile['blood_request_reason'] as String?;

      // Set city fallback for map if not yet set
      if (state.fallbackLatLng == null && city != null) {
        final cityLatLng = _syrianCityCoordinates[city];
        state = state.copyWith(
          neededBloodType: neededBloodType,
          city: city,
          bloodRequestReason: bloodRequestReason,
          fallbackLatLng: cityLatLng,
        );
      } else {
        state = state.copyWith(
          neededBloodType: neededBloodType,
          city: city,
          bloodRequestReason: bloodRequestReason,
        );
      }

      if (neededBloodType == null) {
        state = state.copyWith(isInitialLoading: false);
        return;
      }

      await fetchDonors(loadMore: false);
    } catch (error, stackTrace) {
      AppLogger.error(
        'ReceiverMapNotifier._fetchInitialProfile',
        error,
        stackTrace,
      );
      state = state.copyWith(isInitialLoading: false, hasError: true);
    }
  }

  Future<void> fetchDonors({bool loadMore = false}) async {
    final neededBloodType = state.neededBloodType;
    if (neededBloodType == null) {
      state = state.copyWith(isInitialLoading: false);
      return;
    }

    if (loadMore && (state.isLoadingMore || !state.hasMore)) return;

    final currentOffset = loadMore ? state.offset : 0;
    final existingDonors = loadMore ? state.donors : const <Map<String, dynamic>>[];

    state = state.copyWith(
      donors: existingDonors,
      offset: currentOffset,
      hasMore: loadMore ? state.hasMore : true,
      hasError: false,
      isInitialLoading: loadMore ? state.isInitialLoading : true,
      isLoadingMore: loadMore,
    );

    try {
      final fetchedDonors = await _service.getCompatibleDonors(
        receiverBloodType: neededBloodType,
        offset: currentOffset,
        limit: state.limit,
        receiverCity: state.city,
        receiverLat: state.currentPosition?.latitude,
        receiverLng: state.currentPosition?.longitude,
      );

      final donors = loadMore
          ? [...state.donors, ...fetchedDonors]
          : fetchedDonors;

      state = state.copyWith(
        donors: donors,
        offset: currentOffset + state.limit,
        hasMore: fetchedDonors.length >= state.limit,
        hasError: false,
        isInitialLoading: false,
        isLoadingMore: false,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'ReceiverMapNotifier.fetchDonors',
        error,
        stackTrace,
      );
      state = state.copyWith(
        hasError: true,
        isInitialLoading: false,
        isLoadingMore: false,
      );
    }
  }

  String? _normalizeBloodType(String? rawBloodType) {
    if (rawBloodType == null) return null;

    final candidate = rawBloodType.trim().toUpperCase();
    return receiverBloodTypes.contains(candidate) ? candidate : null;
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
