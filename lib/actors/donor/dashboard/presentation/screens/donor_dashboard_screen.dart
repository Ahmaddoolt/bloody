// file: lib/actors/donor/features/dashboard/presentation/screens/donor_dashboard_screen.dart
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_loader.dart';
import '../../../../../../core/widgets/user_card.dart';
import '../../data/donor_dashboard_service.dart';

class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  final DonorDashboardService _service = DonorDashboardService();

  bool _isMapView = false;
  List<Map<String, dynamic>> _feedItems = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasError = false;

  final int _limit = 50;
  int _offset = 0;
  final ScrollController _scrollController = ScrollController();
  Position? _currentPosition;
  Set<Marker> _markers = {};

  String? _myBloodType;
  String? _myCity;
  int _myPoints = 0;
  String _statusMessage = "initializing".tr();

  bool _isDeferred = false;
  DateTime? _lastDonationDate;
  DateTime? _nextEligibleDate;
  Timer? _countdownTimer;
  Timer? _autoRefreshTimer;
  String _remainingTime = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initData();

    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (!_isDeferred && !_hasError && mounted) {
        _fetchData(loadMore: false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _countdownTimer?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String days = duration.inDays.toString();
    String hours = twoDigits(duration.inHours.remainder(24));
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$days:$hours:$minutes:$seconds";
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    if (_nextEligibleDate == null) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = _nextEligibleDate!.difference(now);

      if (remaining.isNegative) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isDeferred = false;
            _remainingTime = '';
          });
          _fetchData();
        }
      } else {
        if (mounted) setState(() => _remainingTime = _formatDuration(remaining));
      }
    });
  }

  void _onScroll() {
    if (_isMapView || _isDeferred || _hasError) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchData(loadMore: true);
    }
  }

  Future<void> _initData() async {
    await _determinePosition();
    await _fetchData();
  }

  Future<void> _determinePosition() async {
    setState(() => _statusMessage = "checking_location".tr());
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _statusMessage = "";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = "GPS unavailable");
    }
  }

  Future<void> _fetchData({bool loadMore = false}) async {
    if (loadMore && (_isLoadingMore || !_hasMore)) return;

    setState(() {
      _hasError = false;
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        if (_feedItems.isEmpty) _isInitialLoading = true;
        _offset = 0;
        _hasMore = true;
        _feedItems.clear();
      }
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final myProfile = await _service.getDonorProfile(userId);

      if (myProfile == null) throw Exception("Profile not found");

      _myBloodType = (myProfile['blood_type'] as String?)?.trim();
      _myPoints = myProfile['points'] ?? 0;
      _myCity = myProfile['city'];

      if (myProfile['last_donation_date'] != null) {
        _lastDonationDate = DateTime.parse(myProfile['last_donation_date']);
        _nextEligibleDate = _lastDonationDate!.add(const Duration(days: 90));

        if (_nextEligibleDate!.isAfter(DateTime.now())) {
          if (mounted) {
            setState(() {
              _isDeferred = true;
              _isInitialLoading = false;
            });
            _startCountdownTimer();
          }
          return;
        }
      }

      setState(() => _isDeferred = false);
      _countdownTimer?.cancel();

      if (_myBloodType != null) {
        final receivers = await _service.getCompatibleReceivers(
          donorBloodType: _myBloodType!,
          offset: _offset,
          limit: _limit,
          donorCity: _myCity,
          donorLat: _currentPosition?.latitude,
          donorLng: _currentPosition?.longitude,
        );

        if (mounted) {
          if (receivers.length < _limit) _hasMore = false;
          setState(() {
            _feedItems.addAll(receivers);
            _offset += _limit;
            _isLoadingMore = false;
            _isInitialLoading = false;
            _buildMarkers();
          });
        }
      } else {
        if (mounted) setState(() => _isInitialLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  void _buildMarkers() {
    Set<Marker> newMarkers = {};
    for (var item in _feedItems) {
      if (item['latitude'] != null && item['longitude'] != null) {
        final double lat = (item['latitude'] as num).toDouble();
        final double lng = (item['longitude'] as num).toDouble();

        newMarkers.add(
          Marker(
            markerId: MarkerId('receiver_${item['id']}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            infoWindow: InfoWindow(
              title: 'Needs ${item['blood_type']}',
              snippet: 'Tap to call',
              onTap: () => _makeCall(item['phone']),
            ),
          ),
        );
      }
    }
    setState(() => _markers = newMarkers);
  }

  void _makeCall(String? phone) async {
    if (phone == null) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "my_points".tr(args: [_myPoints.toString()]),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (_myBloodType != null)
              Text('matches_for_donor'.tr(args: [_myBloodType!]),
                  style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: (_isDeferred || _isInitialLoading || _hasError)
          ? null
          : FloatingActionButton.extended(
              heroTag: 'donor_map_fab',
              onPressed: () => setState(() => _isMapView = !_isMapView),
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              icon: Icon(_isMapView ? Icons.list : Icons.map),
              label: Text(_isMapView ? "List View" : "nav".tr()),
            ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) return const CustomLoader();

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text("error_loading".tr(), style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _fetchData(), child: Text("retry".tr()))
          ],
        ),
      );
    }

    if (_isDeferred) return _buildDeferralView();
    if (_isMapView) return _buildMap();

    return _buildList();
  }

  Widget _buildDeferralView() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32.0),
        margin: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_rounded, color: AppTheme.primaryRed, size: 80),
            const SizedBox(height: 24),
            Text("thank_you_donor".tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("donation_deferral_notice".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5)),
            const Divider(height: 40),
            Text("time_until_next_donation".tr(),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[700])),
            const SizedBox(height: 12),
            if (_remainingTime.isEmpty)
              const CustomLoader(size: 30)
            else
              Text(_remainingTime,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppTheme.darkRed,
                      fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Text("days : hours : minutes : seconds",
                style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_myBloodType == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bloodtype_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text("blood_type_missing".tr(),
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            // Note: Update path to SettingsScreen later if needed
            ElevatedButton(onPressed: () {}, child: Text("update_settings".tr()))
          ],
        ),
      );
    }

    if (_feedItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => await _fetchData(loadMore: false),
        color: AppTheme.primaryRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  const SizedBox(height: 20),
                  Text("no_receivers_nearby".tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => await _fetchData(loadMore: false),
      color: AppTheme.primaryRed,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
        itemCount: _feedItems.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _feedItems.length)
            return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20), child: CustomLoader(size: 30));
          final item = _feedItems[index];
          return UserCard(userData: item, onTap: () {}, onCall: () => _makeCall(item['phone']));
        },
      ),
    );
  }

  Widget _buildMap() {
    if (_currentPosition == null) return Center(child: Text(_statusMessage));
    return GoogleMap(
      initialCameraPosition: CameraPosition(
          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), zoom: 12),
      myLocationEnabled: true,
      markers: _markers,
    );
  }
}
