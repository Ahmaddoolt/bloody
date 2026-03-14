// file: lib/actors/receiver/map_finder/presentation/screens/receiver_map_screen.dart
// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/map_marker_helper.dart';
import '../../../../../../core/widgets/custom_loader.dart';
import '../../../../../../core/widgets/user_card.dart';
import '../../data/map_finder_service.dart';

class ReceiverHomeScreen extends StatefulWidget {
  const ReceiverHomeScreen({super.key});

  @override
  State<ReceiverHomeScreen> createState() => _ReceiverHomeScreenState();
}

class _ReceiverHomeScreenState extends State<ReceiverHomeScreen> {
  final MapFinderService _service = MapFinderService();

  bool _isMapView = false;
  final List<Map<String, dynamic>> _donors = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  final int _limit = 50;
  int _offset = 0;
  final ScrollController _scrollController = ScrollController();

  Position? _currentPosition;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  BitmapDescriptor? _donorMarkerIcon;

  Timer? _autoRefreshTimer;
  String _statusMessage = '';

  String? _neededBloodType;
  String? _myCity;
  String? _myUserId;

  final List<String> _allBloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _myUserId = Supabase.instance.client.auth.currentUser!.id;
    _scrollController.addListener(_onScroll);
    _loadMarkerIcon();
    _initData();

    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted && _neededBloodType != null) _fetchDonors(loadMore: false);
    });
  }

  Future<void> _loadMarkerIcon() async {
    final icon = await MapMarkerHelper.getDonorMarker();
    if (mounted) {
      setState(() {
        _donorMarkerIcon = icon;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isMapView) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchDonors(loadMore: true);
    }
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> _initData() async {
    await _determinePosition();
    await _fetchInitialProfile();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isInitialLoading) {
        setState(() => _isInitialLoading = false);
      }
    });
  }

  Future<void> _determinePosition() async {
    if (!mounted) return;
    setState(() => _statusMessage = 'checking_location'.tr());
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _statusMessage = 'location_denied'.tr());
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5));
      _updateLocation(pos);
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) _updateLocation(last);
      } catch (_) {}
    }
  }

  void _updateLocation(Position pos) {
    if (!mounted) return;
    setState(() {
      _currentPosition = pos;
      _statusMessage = '';
    });
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 14)));
  }

  String? _normalizeBloodType(String? raw) {
    if (raw == null) return null;
    final c = raw.trim().toUpperCase();
    return _allBloodTypes.contains(c) ? c : null;
  }

  Future<void> _fetchInitialProfile() async {
    try {
      final profile = await _service.getReceiverProfile(_myUserId!);
      if (mounted && profile != null) {
        final bt = _normalizeBloodType(profile['blood_type']);
        setState(() {
          _neededBloodType = bt;
          _myCity = profile['city'];
        });
        if (bt != null) {
          await _fetchDonors();
        } else {
          setState(() => _isInitialLoading = false);
        }
      } else {
        if (mounted) setState(() => _isInitialLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _fetchDonors({bool loadMore = false}) async {
    if (_neededBloodType == null) {
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }
    if (loadMore && (_isLoadingMore || !_hasMore)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        if (_donors.isEmpty) _isInitialLoading = true;
        _offset = 0;
        _hasMore = true;
        _donors.clear();
      }
    });

    try {
      final fetched = await _service.getCompatibleDonors(
        receiverBloodType: _neededBloodType!,
        offset: _offset,
        limit: _limit,
        receiverCity: _myCity,
        receiverLat: _currentPosition?.latitude,
        receiverLng: _currentPosition?.longitude,
      );
      if (mounted) {
        if (fetched.length < _limit) _hasMore = false;
        setState(() {
          _donors.addAll(fetched);
          _offset += _limit;
          _isInitialLoading = false;
          _isLoadingMore = false;
          _buildMarkers();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _buildMarkers() {
    final markers = <Marker>{};
    for (final d in _donors) {
      if (d['latitude'] == null || d['longitude'] == null) continue;
      markers.add(Marker(
        markerId: MarkerId(d['id']),
        position: LatLng(d['latitude'], d['longitude']),
        icon: _donorMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: '${'donor'.tr()}: ${d['blood_type']}',
          snippet: 'tap_to_see_details'.tr(),
          onTap: () => _showDonorModal(d),
        ),
      ));
    }
    setState(() => _markers = markers);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _confirmDonation(String donorId, String donorName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('confirm_donation'.tr()),
        content: Text('confirm_donation_body'.tr(args: [donorName])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr())),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('yes_confirm'.tr())),
        ],
      ),
    );
    if (ok != true) return;

    final success = await _service.confirmDonation(donorId);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      _showSnack('donation_confirmed'.tr(args: [donorName]), Colors.green);
      _fetchDonors(loadMore: false);
    } else {
      _showSnack('error_updating_donor'.tr(), Colors.red);
    }
  }

  void _showDonorModal(Map<String, dynamic> user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient header strip
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryRed, AppTheme.darkRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const Icon(Icons.volunteer_activism_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'donor_details'.tr(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  UserCard(
                    userData: user,
                    onTap: () {},
                    onCall: () => _callUser(user['phone']),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmDonation(
                          user['id'], user['email']?.split('@')[0] ?? 'Donor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text('confirm_they_donated'.tr(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _callUser(String? phone) async {
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: _buildGradientAppBar(),
      body: Column(children: [
        _buildBloodTypeSelector(isDark),
        Expanded(
            child: _isInitialLoading
                ? const CustomLoader()
                : _isMapView
                    ? _buildMap()
                    : _buildList(isDark)),
      ]),
      floatingActionButton: _buildFABGroup(isDark),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────

  PreferredSizeWidget _buildGradientAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryRed, AppTheme.darkRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'find_donors'.tr(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          if (_donors.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_donors.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  // ── Blood type pill selector ────────────────────────────────────

  Widget _buildBloodTypeSelector(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 3),
              blurRadius: 6)
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _allBloodTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _allBloodTypes[i];
          final selected = _neededBloodType == t;
          return GestureDetector(
            onTap: () {
              setState(() => _neededBloodType = t);
              _fetchDonors(loadMore: false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryRed
                    : (isDark ? AppTheme.darkCard : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppTheme.primaryRed
                      : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryRed.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                t,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFABGroup(bool isDark) {
    return FloatingActionButton(
      heroTag: 'receiver_map_fab',
      onPressed: () => setState(() => _isMapView = !_isMapView),
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      foregroundColor: AppTheme.primaryRed,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: AppTheme.primaryRed.withOpacity(0.35), width: 1.5),
      ),
      child:
          Icon(_isMapView ? Icons.list_rounded : Icons.map_rounded, size: 22),
    );
  }

  Widget _buildList(bool isDark) {
    if (_donors.isEmpty) {
      return _buildEmptyState(isDark);
    }
    return Column(children: [
      _buildCompatibilityBanner(isDark),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async => _fetchDonors(loadMore: false),
          color: AppTheme.primaryRed,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            itemCount: _donors.length + (_hasMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _donors.length) {
                return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CustomLoader(size: 28));
              }
              return _StaggeredItem(
                delay: Duration(milliseconds: (i * 60).clamp(0, 600)),
                child: GestureDetector(
                  onTap: () => _showDonorModal(_donors[i]),
                  child: AbsorbPointer(
                      child: UserCard(
                          userData: _donors[i], onTap: () {}, onCall: () {})),
                ),
              );
            },
          ),
        ),
      ),
    ]);
  }

  Widget _buildEmptyState(bool isDark) {
    return RefreshIndicator(
      onRefresh: () async => _fetchDonors(loadMore: false),
      color: AppTheme.primaryRed,
      child: LayoutBuilder(builder: (ctx, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.primaryRed.withOpacity(0.15),
                            AppTheme.primaryRed.withOpacity(0.04),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          size: 52, color: AppTheme.primaryRed),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'no_compatible_donors'.tr(args: [_neededBloodType ?? '']),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'check_back_later'.tr(),
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? Colors.grey[500] : Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCompatibilityBanner(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1B5E20).withOpacity(0.7)
              : Colors.green.shade50,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: isDark
                  ? Colors.green.withOpacity(0.3)
                  : Colors.green.shade200,
              width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 14,
                color: isDark ? Colors.green[300] : Colors.green[700]),
            const SizedBox(width: 6),
            Text(
              'showing_donors_compatible'.tr(args: [_neededBloodType ?? '']),
              style: TextStyle(
                  color: isDark ? Colors.green[300] : Colors.green[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.green.withOpacity(0.2)
                    : Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${_donors.length}',
                  style: TextStyle(
                      color: isDark ? Colors.green[300] : Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_currentPosition == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_off_rounded,
                      color: AppTheme.primaryRed, size: 34),
                ),
                const SizedBox(height: 20),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _determinePosition,
                  icon: const Icon(Icons.my_location_rounded),
                  label: Text('retry_gps'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return GoogleMap(
      initialCameraPosition: CameraPosition(
          target:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 14),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: _markers,
      onMapCreated: (c) => _mapController = c,
    );
  }
}

// ── Staggered list item ────────────────────────────────────────────────────

class _StaggeredItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _StaggeredItem({required this.child, required this.delay});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
