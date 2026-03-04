import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/custom_loader.dart';
import '../../data/donor_dashboard_service.dart';
import '../widgets/deferral_view.dart';
import '../widgets/donor_header.dart';
import '../widgets/receiver_list.dart';

class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen>
    with SingleTickerProviderStateMixin {
  final _service = DonorDashboardService();
  final _scrollController = ScrollController();

  bool _isMapView = false;
  List<Map<String, dynamic>> _feedItems = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasError = false;

  final int _limit = 50;
  int _offset = 0;
  Position? _currentPosition;
  Set<Marker> _markers = {};

  String? _myBloodType;
  String? _myCity;
  int _myPoints = 0;
  String _statusMessage = '';

  bool _isDeferred = false;
  DateTime? _lastDonationDate;
  DateTime? _nextEligibleDate;
  Timer? _countdownTimer;
  Timer? _autoRefreshTimer;
  String _remainingTime = '';

  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

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
    _initData();

    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!_isDeferred && !_hasError && mounted) _fetchData(loadMore: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _countdownTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _ringCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${d.inDays}d  ${pad(d.inHours.remainder(24))}h'
        '  ${pad(d.inMinutes.remainder(60))}m'
        '  ${pad(d.inSeconds.remainder(60))}s';
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    if (_nextEligibleDate == null) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final remaining = _nextEligibleDate!.difference(DateTime.now());
      if (remaining.isNegative) {
        t.cancel();
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

  double _calculateDeferralProgress() {
    if (_lastDonationDate == null || _nextEligibleDate == null) return 0;
    final total = _nextEligibleDate!.difference(_lastDonationDate!).inSeconds;
    final elapsed = DateTime.now().difference(_lastDonationDate!).inSeconds;
    return total <= 0 ? 1.0 : (elapsed / total).clamp(0.0, 1.0);
  }

  void _onScroll() {
    if (_isMapView || _isDeferred || _hasError) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchData(loadMore: true);
    }
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _initData() async {
    await _determinePosition();
    await _fetchData();
  }

  Future<void> _determinePosition() async {
    setState(() => _statusMessage = 'checking_location'.tr());
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _statusMessage = 'location_denied'.tr());
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _statusMessage = '';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statusMessage = 'gps_unavailable'.tr());
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
      if (myProfile == null) throw Exception('Profile not found');

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
    } catch (_) {
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
    final markers = <Marker>{};
    for (final item in _feedItems) {
      if (item['latitude'] == null || item['longitude'] == null) continue;
      markers.add(Marker(
        markerId: MarkerId('receiver_${item['id']}'),
        position: LatLng(
          (item['latitude'] as num).toDouble(),
          (item['longitude'] as num).toDouble(),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
          title: 'Needs ${item['blood_type']}',
          snippet: 'tap_to_call'.tr(),
          onTap: () => _makeCall(item['phone']),
        ),
      ));
    }
    setState(() => _markers = markers);
  }

  void _makeCall(String? phone) async {
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton:
          (_isDeferred || _isInitialLoading || _hasError) ? null : _buildFAB(),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) return const CustomLoader();
    if (_hasError) return DonorErrorState(onRetry: () => _fetchData());

    if (_isDeferred) {
      return DeferralView(
        progress: _calculateDeferralProgress(),
        remainingTime: _remainingTime,
        ringAnimation: _ringAnim,
      );
    }

    return Column(
      children: [
        DonorHeader(
          bloodType: _myBloodType,
          points: _myPoints,
          receiverCount: _feedItems.length,
          city: _myCity,
        ),
        Expanded(
          child: _isMapView
              ? _buildMap()
              : ReceiverList(
                  items: _feedItems,
                  bloodType: _myBloodType,
                  hasMore: _hasMore,
                  scrollController: _scrollController,
                  onRefresh: () => _fetchData(loadMore: false),
                  onCall: _makeCall,
                ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    if (_currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CustomLoader(),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        zoom: 12,
      ),
      myLocationEnabled: true,
      markers: _markers,
    );
  }

  Widget _buildFAB() {
    final isMap = _isMapView;

    return FloatingActionButton(
      heroTag: 'donor_map_fab',
      onPressed: () => setState(() => _isMapView = !_isMapView),
      backgroundColor: isMap ? Colors.white : AppColors.accent,
      foregroundColor: isMap ? AppColors.accent : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isMap
            ? BorderSide(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      child: Icon(isMap ? Icons.list_rounded : Icons.map_rounded, size: 24),
    );
  }
}
