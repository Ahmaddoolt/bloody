import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/map_marker_helper.dart';
import '../../../../../core/widgets/app_loading_indicator.dart';
import '../../../../../core/widgets/map_toggle_fab.dart';
import '../providers/deferral_timer_provider.dart';
import '../providers/donor_dashboard_provider.dart';
import '../providers/donor_profile_provider.dart';
import '../providers/receiver_list_provider.dart';
import '../widgets/deferral_view.dart';
import '../widgets/receiver_list.dart';

class DonorHomeScreen extends ConsumerStatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  ConsumerState<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends ConsumerState<DonorHomeScreen>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;
  AutoRefreshController? _autoRefreshController;
  BitmapDescriptor? _receiverMarkerIcon;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _ringAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut),
    );

    _scrollController.addListener(_onScroll);
    _loadMarkerIcon();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoRefreshController = ref.read(autoRefreshProvider);
      _initData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ringCtrl.dispose();
    _autoRefreshController?.stop();
    super.dispose();
  }

  Future<void> _loadMarkerIcon() async {
    final icon = await MapMarkerHelper.getReceiverMarker();
    if (mounted) {
      setState(() {
        _receiverMarkerIcon = icon;
      });
    }
  }

  void _onScroll() {
    final isMapView = ref.read(isMapViewProvider);
    final deferralState = ref.read(deferralTimerProvider);
    final receiverState = ref.read(receiverListProvider);

    if (isMapView || deferralState.isDeferred || receiverState.hasError) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _initData() async {
    if (!mounted) return;
    await ref.read(donorLocationNotifierProvider.notifier).determinePosition();
    if (!mounted) return;
    await _loadProfileAndReceivers();
    if (!mounted) return;
    _autoRefreshController?.start();
  }

  Future<void> _loadProfileAndReceivers() async {
    if (!mounted) return;

    // Use refresh to get the new value immediately
    final profile = await ref.refresh(donorProfileProvider.future);

    if (!mounted) return;

    if (profile != null) {
      _handleProfileData(profile);
    }
  }

  void _handleProfileData(Map<String, dynamic> profile) {
    final lastDonationDate = profile['last_donation_date'] != null
        ? DateTime.parse(profile['last_donation_date'])
        : null;

    if (lastDonationDate != null) {
      final nextEligibleDate = lastDonationDate.add(const Duration(days: 90));

      if (nextEligibleDate.isAfter(DateTime.now())) {
        ref
            .read(deferralTimerProvider.notifier)
            .startDeferralPeriod(lastDonationDate);
        return;
      }
    }

    ref.read(deferralTimerProvider.notifier).clearDeferral();
    _loadReceivers(profile);
  }

  void _loadReceivers(Map<String, dynamic> profile) {
    final location = ref.read(donorLocationProvider);
    final bloodType = profile['blood_type'] as String?;

    if (bloodType != null) {
      ref.read(receiverListProvider.notifier).fetchReceivers(
            donorBloodType: bloodType,
            donorCity: profile['city'] as String?,
            donorLat: location.latitude,
            donorLng: location.longitude,
          );
    }
  }

  void _loadMore() {
    final profileAsync = ref.read(donorProfileProvider);
    final location = ref.read(donorLocationProvider);

    profileAsync.whenOrNull(
      data: (profile) {
        if (profile != null) {
          final bloodType = profile['blood_type'] as String?;
          if (bloodType != null) {
            ref.read(receiverListProvider.notifier).fetchReceivers(
                  donorBloodType: bloodType,
                  donorCity: profile['city'] as String?,
                  donorLat: location.latitude,
                  donorLng: location.longitude,
                  loadMore: true,
                );
          }
        }
      },
    );
  }

  void _makeCall(String? phone) async {
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final deferralState = ref.watch(deferralTimerProvider);
    final receiverState = ref.watch(receiverListProvider);
    final isMapView = ref.watch(isMapViewProvider);
    final profileAsync = ref.watch(donorProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Show deferral view (no AppBar, full screen)
    if (deferralState.isDeferred) {
      return DeferralView(
        progress: deferralState.progress,
        remainingTime: deferralState.remainingTime,
        ringAnimation: _ringAnim,
      );
    }

    // Show loading
    if (receiverState.isLoading && receiverState.items.isEmpty) {
      return const Scaffold(
        body: AppLoadingCenter(),
      );
    }

    // Show error
    if (receiverState.hasError) {
      return Scaffold(
        body: _buildErrorState(),
      );
    }

    // Show main dashboard with AppBar
    return profileAsync.when(
      loading: () => const Scaffold(
        body: AppLoadingCenter(),
      ),
      error: (_, __) => Scaffold(
        body: _buildErrorState(),
      ),
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            body: _buildErrorState(),
          );
        }

        final bloodType = profile['blood_type'] as String?;
        final points = profile['points'] ?? 0;
        final city = profile['city'] as String?;

        return Scaffold(
          appBar: _buildAppBar(
              bloodType, points, receiverState.totalCount, city, colorScheme),
          body: ref.watch(isMapViewProvider)
              ? _buildMap(receiverState.items)
              : ReceiverList(
                  items: receiverState.items,
                  bloodType: bloodType,
                  hasMore: receiverState.hasMore,
                  scrollController: _scrollController,
                  onRefresh: _loadProfileAndReceivers,
                  onCall: _makeCall,
                ),
          floatingActionButton: MapToggleFab(
            isMapView: ref.watch(isMapViewProvider),
            onToggle: () => ref.read(isMapViewProvider.notifier).state =
                !ref.read(isMapViewProvider),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(String? bloodType, int points,
      int receiverCount, String? city, ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: AppColors.accent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 120,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentDark, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Blood Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bloodtype_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            bloodType ?? '--',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Points Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$points',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'ready_to_save'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$receiverCount ${'receivers'.tr()}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                    if (city != null) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        city.tr(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'error_loading_data'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'check_connection'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loadProfileAndReceivers,
            icon: const Icon(Icons.refresh),
            label: Text('retry'.tr()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(List<Map<String, dynamic>> items) {
    final location = ref.watch(donorLocationProvider);

    if (location.latitude == null || location.longitude == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLoadingCenter(size: 40),
            const SizedBox(height: 20),
            Text(
              location.status?.isNotEmpty == true ? location.status!.tr() : '',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    final markers = _buildMarkers(items);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(location.latitude!, location.longitude!),
          zoom: 12,
        ),
        myLocationEnabled: true,
        markers: markers,
      ),
    );
  }

  Set<Marker> _buildMarkers(List<Map<String, dynamic>> items) {
    final markers = <Marker>{};
    for (final item in items) {
      if (item['latitude'] == null || item['longitude'] == null) continue;
      markers.add(Marker(
        markerId: MarkerId('receiver_${item['id']}'),
        position: LatLng(
          (item['latitude'] as num).toDouble(),
          (item['longitude'] as num).toDouble(),
        ),
        icon: _receiverMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
          title: '${'needs'.tr()} ${item['blood_type']}',
          snippet: 'tap_to_call'.tr(),
          onTap: () => _makeCall(item['phone']),
        ),
      ));
    }
    return markers;
  }
}
