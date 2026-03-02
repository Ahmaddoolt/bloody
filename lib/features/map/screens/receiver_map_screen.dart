// file: lib/features/map/screens/receiver_map_screen.dart
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/blood_utils.dart';
import '../../../core/utils/sorting_utils.dart';
import '../../../core/widgets/custom_loader.dart';
import '../../../core/widgets/user_card.dart';

class ReceiverHomeScreen extends StatefulWidget {
  const ReceiverHomeScreen({super.key});

  @override
  State<ReceiverHomeScreen> createState() => _ReceiverHomeScreenState();
}

class _ReceiverHomeScreenState extends State<ReceiverHomeScreen> {
  bool _isMapView = false;
  List<Map<String, dynamic>> _donors = [];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  final int _limit = 50;
  int _offset = 0;
  final ScrollController _scrollController = ScrollController();

  Position? _currentPosition;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  Timer? _autoRefreshTimer;

  String _statusMessage = "initializing".tr();

  String? _neededBloodType;
  String? _myCity;

  final List<String> _allBloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initData();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted && _neededBloodType != null) {
        _fetchDonors(loadMore: false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isMapView) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchDonors(loadMore: true);
    }
  }

  Future<void> _initData() async {
    _determinePosition();
    await _fetchInitialProfile();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isInitialLoading) {
        setState(() => _isInitialLoading = false);
      }
    });
  }

  Future<void> _determinePosition() async {
    if (!mounted) return;
    setState(() => _statusMessage = "checking_location".tr());

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _statusMessage = "Location denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _statusMessage = "Location permanently denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 5));
      _updateLocation(position);
    } catch (e) {
      try {
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) _updateLocation(lastKnown);
      } catch (_) {}
    }
  }

  void _updateLocation(Position position) {
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
      _statusMessage = "";
    });
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 14),
        ),
      );
    }
  }

  String? _normalizeBloodType(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toUpperCase();
    if (_allBloodTypes.contains(clean)) return clean;
    return null;
  }

  Future<void> _fetchInitialProfile() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    try {
      final myProfile =
          await supabase.from('profiles').select('blood_type, city').eq('id', userId).maybeSingle();

      if (mounted) {
        if (myProfile != null && myProfile['blood_type'] != null) {
          final normalized = _normalizeBloodType(myProfile['blood_type']);

          setState(() {
            _neededBloodType = normalized;
            _myCity = myProfile['city'];
          });

          if (normalized != null) {
            await _fetchDonors();
          } else {
            setState(() => _isInitialLoading = false);
          }
        } else {
          setState(() => _isInitialLoading = false);
        }
      }
    } catch (e) {
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

    final supabase = Supabase.instance.client;
    try {
      final List<String> compatibleDonors = BloodUtils.getCompatibleDonors(_neededBloodType!);

      final bool isUniversalReceiver = compatibleDonors.length >= 8;

      var query = supabase.from('profiles').select().eq('user_type', 'donor');

      if (!isUniversalReceiver) {
        query = query.filter('blood_type', 'in', compatibleDonors);
      }

      final response = await query.range(_offset, _offset + _limit - 1);

      if (mounted) {
        final List<dynamic> data = response as List<dynamic>;
        final List<Map<String, dynamic>> fetchedDonors = List<Map<String, dynamic>>.from(data);

        final now = DateTime.now();
        fetchedDonors.removeWhere((donor) {
          if (donor['last_donation_date'] == null) return false;
          try {
            final lastDate = DateTime.parse(donor['last_donation_date']);
            final readyDate = lastDate.add(const Duration(days: 90));
            return now.isBefore(readyDate);
          } catch (e) {
            return false;
          }
        });

        SortingUtils.sortDonors(
          fetchedDonors,
          receiverBloodType: _neededBloodType,
          receiverCity: _myCity,
          receiverLat: _currentPosition?.latitude,
          receiverLng: _currentPosition?.longitude,
        );

        if (data.length < _limit) {
          _hasMore = false;
        }

        setState(() {
          _donors.addAll(fetchedDonors);
          _offset += _limit;
          _isInitialLoading = false;
          _isLoadingMore = false;
          _buildMarkers();
        });
      }
    } catch (e) {
      debugPrint("Error fetching donors: $e");
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _buildMarkers() {
    Set<Marker> newMarkers = {};
    for (var user in _donors) {
      if (user['latitude'] != null && user['longitude'] != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(user['id']),
            position: LatLng(user['latitude'], user['longitude']),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'Donor: ${user['blood_type']}',
              snippet: 'Tap to see details',
              onTap: () {
                _showDonorModal(user);
              },
            ),
          ),
        );
      }
    }
    setState(() => _markers = newMarkers);
  }

  Future<void> _confirmDonation(String donorId, String donorName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("confirm_donation".tr()),
        content: Text("confirm_donation_body".tr(args: [donorName])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("cancel".tr())),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text("yes_confirm".tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;
      final today = DateTime.now().toIso8601String().split('T')[0];

      final data = await supabase.from('profiles').select('points').eq('id', donorId).single();
      int currentPoints = data['points'] ?? 0;

      await supabase.from('profiles').update({
        'points': currentPoints + 10,
        'last_donation_date': today,
      }).eq('id', donorId);

      await supabase.from('donations').insert({
        'donor_id': donorId,
        'status': 'completed',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("donation_confirmed".tr(args: [donorName])),
              backgroundColor: Colors.green),
        );
        _fetchDonors(loadMore: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error updating donor status"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDonorModal(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            UserCard(
              userData: user,
              onTap: () {},
              onCall: () => _callUser(user['phone']),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  _confirmDonation(user['id'], user['email']?.split('@')[0] ?? 'Donor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check_circle),
              label: Text("confirm_they_donated".tr()),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _callUser(String? phone) async {
    if (phone == null) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("find_donors".tr()),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 4,
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.bloodtype, color: AppTheme.primaryRed),
                const SizedBox(width: 12),
                Text(
                  "i_need_type".tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _neededBloodType,
                        hint: Text("select".tr()),
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        items: _allBloodTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _neededBloodType = val);
                            _fetchDonors(loadMore: false);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isInitialLoading
                ? const CustomLoader()
                : _isMapView
                    ? _buildMap()
                    : _buildList(isDark),
          ),
        ],
      ),
      // ✅ FIX: Added unique heroTag to prevent collision
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'receiver_map_fab',
        onPressed: () {
          setState(() {
            _isMapView = !_isMapView;
          });
        },
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        icon: Icon(_isMapView ? Icons.list : Icons.map),
        label: Text(_isMapView ? "List View" : "nav".tr()),
      ),
    );
  }

  Widget _buildList(bool isDark) {
    if (_donors.isEmpty && !_isInitialLoading) {
      return RefreshIndicator(
        onRefresh: () async => await _fetchDonors(loadMore: false),
        color: AppTheme.primaryRed,
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      size: 80,
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "no_compatible_donors".tr(args: [_neededBloodType ?? '']),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: isDark ? const Color(0xFF1B5E20) : Colors.green.shade50,
          child: Text(
            "showing_donors_compatible".tr(args: [_neededBloodType ?? '']),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => await _fetchDonors(loadMore: false),
            color: AppTheme.primaryRed,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: 80,
              ),
              itemCount: _donors.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _donors.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CustomLoader(size: 30),
                  );
                }
                final donor = _donors[index];
                return GestureDetector(
                  onTap: () => _showDonorModal(donor),
                  child: AbsorbPointer(
                    child: UserCard(
                      userData: donor,
                      onTap: () {},
                      onCall: () {},
                    ),
                  ),
                );
              },
            ),
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
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
                onPressed: _determinePosition,
                icon: const Icon(Icons.refresh),
                label: Text("retry_gps".tr()))
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 14,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: _markers,
      onMapCreated: (ctrl) => _mapController = ctrl,
    );
  }
}
