// file: lib/actors/donor/dashboard/presentation/screens/donor_dashboard_screen.dart
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

class _DonorHomeScreenState extends State<DonorHomeScreen> with SingleTickerProviderStateMixin {
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
  GoogleMapController? _mapController;

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

  // Shimmer pulse for deferred ring
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _ringAnim = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut));

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

  // ── Helpers ────────────────────────────────────────────────────────────────

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchData(loadMore: true);
    }
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _initData() async {
    await _determinePosition();
    await _fetchData();
  }

  Future<void> _determinePosition() async {
    setState(() => _statusMessage = "checking_location".tr());
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _statusMessage = "location_denied".tr());
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 5));
      if (mounted)
        setState(() {
          _currentPosition = pos;
          _statusMessage = '';
        });
    } catch (_) {
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
        position:
            LatLng((item['latitude'] as num).toDouble(), (item['longitude'] as num).toDouble()),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
          title: 'Needs ${item['blood_type']}',
          snippet: 'Tap to call',
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF5F6FA),
      body: _buildBody(isDark),
      floatingActionButton:
          (_isDeferred || _isInitialLoading || _hasError) ? null : _buildFAB(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isInitialLoading) return const CustomLoader();

    if (_hasError) return _buildErrorState(isDark);
    if (_isDeferred) return _buildDeferralView(isDark);

    return Column(children: [
      _buildAppHeader(isDark),
      Expanded(child: _isMapView ? _buildMap() : _buildList(isDark)),
    ]);
  }

  // ─── Gradient App Header ───────────────────────────────────────────────────

  Widget _buildAppHeader(bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.darkRed, AppTheme.primaryRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: greeting + points badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'matches_for_donor'.tr(args: [_myBloodType ?? '—']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  _PointsBadge(points: _myPoints),
                ],
              ),
              const SizedBox(height: 12),
              // Stats row
              Row(
                children: [
                  _StatPill(
                    icon: Icons.people_alt_rounded,
                    label: '${_feedItems.length} receivers',
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  if (_myCity != null)
                    _StatPill(
                      icon: Icons.location_on_rounded,
                      label: _myCity!,
                      color: Colors.white,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Deferral view ─────────────────────────────────────────────────────────

  Widget _buildDeferralView(bool isDark) {
    final progress = _calculateDeferralProgress();

    return Column(
      children: [
        // Gradient header strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.darkRed, AppTheme.primaryRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Text(
              'thank_you_donor'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress ring card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryRed.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Circular progress
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _ringAnim,
                              builder: (_, __) => SizedBox(
                                width: 160,
                                height: 160,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 10,
                                  backgroundColor: const Color(0xFFE65100).withOpacity(0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.lerp(const Color(0xFFE65100), const Color(0xFF2E7D32),
                                            progress) ??
                                        AppTheme.primaryRed,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'recovered'.tr(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'donation_deferral_notice'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Countdown box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFE65100).withOpacity(0.25), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'time_until_next_donation'.tr(),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 10),
                            _remainingTime.isEmpty
                                ? const CustomLoader(size: 24)
                                : Text(
                                    _remainingTime,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : AppTheme.darkRed,
                                      fontFamily: 'monospace',
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Health tip card
                _buildHealthTipCard(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTipCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade700.withOpacity(isDark ? 0.15 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade700.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.shade700.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.tips_and_updates_rounded, color: Colors.blue.shade700, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('recovery_tip_title'.tr(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text('recovery_tip_body'.tr(),
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error state ───────────────────────────────────────────────────────────

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text("error_loading".tr(),
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text("check_connection".tr(),
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchData(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text("retry".tr()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── List ──────────────────────────────────────────────────────────────────

  Widget _buildList(bool isDark) {
    if (_myBloodType == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bloodtype_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text("blood_type_missing".tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_feedItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _fetchData(loadMore: false),
        color: AppTheme.primaryRed,
        child: LayoutBuilder(builder: (_, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(isDark ? 0.1 : 0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "no_receivers_nearby".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ]),
              ),
            ),
          );
        }),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchData(loadMore: false),
      color: AppTheme.primaryRed,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _feedItems.length + (_hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == _feedItems.length) {
            return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20), child: CustomLoader(size: 28));
          }
          final item = _feedItems[i];
          return UserCard(userData: item, onTap: () {}, onCall: () => _makeCall(item['phone']));
        },
      ),
    );
  }

  // ─── Map ───────────────────────────────────────────────────────────────────

  Widget _buildMap() {
    if (_currentPosition == null) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CustomLoader(),
          const SizedBox(height: 20),
          Text(_statusMessage, style: const TextStyle(color: Colors.grey)),
        ],
      ));
    }
    return GoogleMap(
      initialCameraPosition: CameraPosition(
          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), zoom: 12),
      myLocationEnabled: true,
      markers: _markers,
      onMapCreated: (c) => _mapController = c,
    );
  }

  // ─── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFAB(bool isDark) {
    return FloatingActionButton(
      heroTag: 'donor_map_fab',
      onPressed: () => setState(() => _isMapView = !_isMapView),
      backgroundColor: _isMapView ? Colors.white : AppTheme.primaryRed,
      foregroundColor: _isMapView ? AppTheme.primaryRed : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: _isMapView
            ? BorderSide(color: AppTheme.primaryRed.withOpacity(0.4), width: 1.5)
            : BorderSide.none,
      ),
      child: Icon(_isMapView ? Icons.list_rounded : Icons.map_rounded, size: 24),
    );
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 6),
          Text(
            '$points pts',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
