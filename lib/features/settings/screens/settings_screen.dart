// file: lib/features/settings/screens/settings_screen.dart
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart'; // ✅ IMPORTED LOGGER
import '../../../core/widgets/custom_loader.dart';
import '../../auth/screens/login_screen.dart';
import '../../notifications/screens/notifications_screen.dart'; // ✅ IMPORTED NOTIFICATIONS
import 'widgets/donation_history_list.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();

  String? _selectedBloodType;
  String? _selectedCity;
  DateTime? _selectedDate;

  bool _isLoading = false;
  bool _isHistoryLoading = false;
  List<Map<String, dynamic>> _donationHistory = [];

  bool _isDeferred = false;
  DateTime? _lastDonationDate;
  DateTime? _nextEligibleDate;
  Timer? _countdownTimer;
  String _remainingTime = '';

  bool _isDonor = true;
  String _priorityStatus = 'none';
  bool _isRequestingPriority = false;

  bool get _isArabic => context.locale.languageCode == 'ar';

  final String _userId = Supabase.instance.client.auth.currentUser!.id;
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  final List<String> _syrianCities = [
    'Damascus',
    'Aleppo',
    'Homs',
    'Hama',
    'Latakia',
    'Tartus',
    'Idlib',
    'Daraa',
    'As-Suwayda',
    'Quneitra',
    'Deir ez-Zor',
    'Al-Hasakah',
    'Raqqa',
    'Rif Dimashq'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final days = duration.inDays.toString();
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$days:$hours:$minutes:$seconds';
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    if (_nextEligibleDate == null) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _nextEligibleDate!.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        if (mounted)
          setState(() {
            _isDeferred = false;
            _remainingTime = '';
          });
      } else {
        if (mounted) setState(() => _remainingTime = _formatDuration(remaining));
      }
    });
  }

  double _calculateProgress() {
    if (_lastDonationDate == null || _nextEligibleDate == null) return 0;
    final total = _nextEligibleDate!.difference(_lastDonationDate!).inSeconds;
    final elapsed = DateTime.now().difference(_lastDonationDate!).inSeconds;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  // ── Data Loading ─────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      AppLogger.info("Loading profile for user: $_userId");

      final data =
          await Supabase.instance.client.from('profiles').select().eq('id', _userId).single();

      if (mounted) {
        setState(() {
          _phoneController.text = data['phone'] ?? '';
          _usernameController.text = data['username'] ?? '';

          if (_bloodTypes.contains(data['blood_type'])) {
            _selectedBloodType = data['blood_type'];
          }
          if (_syrianCities.contains(data['city'])) {
            _selectedCity = data['city'];
          }
          if (data['birth_date'] != null) {
            _selectedDate = DateTime.tryParse(data['birth_date']);
          }

          final userType = data['user_type'] ?? 'donor';
          _isDonor = (userType == 'donor');

          _priorityStatus = data['priority_status'] ?? 'none';
          AppLogger.info("Current Priority Status: $_priorityStatus");

          if (_isDonor) {
            _fetchDonationHistory();
            if (data['last_donation_date'] != null) {
              _lastDonationDate = DateTime.parse(data['last_donation_date']);
              _nextEligibleDate = _lastDonationDate!.add(const Duration(days: 90));

              if (_nextEligibleDate!.isAfter(DateTime.now())) {
                _isDeferred = true;
                _startCountdownTimer();
              } else {
                _isDeferred = false;
              }
            }
          }
        });
      }
    } catch (e, stack) {
      AppLogger.error("SettingsScreen._loadProfile", e, stack);
    }
  }

  Future<void> _fetchDonationHistory() async {
    if (!_isDonor) return;
    setState(() => _isHistoryLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('donations')
          .select('*, centers(name)')
          .eq('donor_id', _userId)
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _donationHistory = List<Map<String, dynamic>>.from(response);
          _isHistoryLoading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error("SettingsScreen._fetchDonationHistory", e, stack);
      if (mounted) setState(() => _isHistoryLoading = false);
    }
  }

  // ── Priority Request ─────────────────────────────────────────────────────

  Future<void> _requestHighPriority() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Request High Priority'),
        content: const Text(
          'You are requesting high-priority status. An admin will review your '
          'request and approve or reject it. Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr(), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRequestingPriority = true);

    try {
      AppLogger.info("Attempting to set priority_status = pending for $_userId");

      await Supabase.instance.client
          .from('profiles')
          .update({'priority_status': 'pending'}).eq('id', _userId);

      if (mounted) {
        setState(() => _priorityStatus = 'pending');
        AppLogger.success("Priority request submitted successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Priority request submitted. Awaiting admin approval.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.error("SettingsScreen._requestHighPriority", e, stack);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequestingPriority = false);
    }
  }

  // ── Profile Update ────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('profiles').update({
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'blood_type': _selectedBloodType,
        'city': _selectedCity,
        'birth_date': _selectedDate?.toIso8601String().split('T')[0],
      }).eq('id', _userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_updated'.tr())),
        );
      }
    } catch (e, stack) {
      AppLogger.error("SettingsScreen._updateProfile", e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating profile'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e, stack) {
      AppLogger.error("SettingsScreen._handleLogout", e, stack);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, currentMode, child) {
        final bool isDarkMode = currentMode == ThemeMode.dark;
        final dropdownColor = isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;

        return Scaffold(
          appBar: AppBar(
            title: Text('settings'.tr()),
            actions: [
              // 🔔 Simple Notification Icon (Navigate Only)
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                tooltip: 'Notifications',
              ),

              // 🚪 Logout Icon
              IconButton(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'log_out'.tr(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isDonor) ...[
                  _buildEligibilityCard(isDarkMode),
                  const SizedBox(height: 24),
                ],

                // ── Priority Request Card (Needy Users Only) ──────────────
                if (!_isDonor) ...[
                  _buildPriorityCard(isDarkMode),
                  const SizedBox(height: 24),
                ],

                Text(
                  'app_settings'.tr(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: AppTheme.primaryRed,
                  ),
                  title: Text('dark_mode'.tr()),
                  trailing: Switch(
                    value: isDarkMode,
                    activeColor: AppTheme.primaryRed,
                    onChanged: (val) {
                      AppTheme.saveTheme(val ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language, color: AppTheme.primaryRed),
                  title: Text('arabic_lang'.tr()),
                  trailing: Switch(
                    value: _isArabic,
                    activeColor: AppTheme.primaryRed,
                    onChanged: (val) async {
                      if (val) {
                        await context.setLocale(const Locale('ar'));
                      } else {
                        await context.setLocale(const Locale('en'));
                      }
                      setState(() {});
                    },
                  ),
                ),

                const Divider(height: 40),

                Text(
                  'my_info'.tr(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'username'.tr(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'phone_number'.tr(),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  dropdownColor: dropdownColor,
                  items: _syrianCities
                      .map((city) => DropdownMenuItem(value: city, child: Text(city.tr())))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCity = val),
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedBloodType,
                  dropdownColor: dropdownColor,
                  items: _bloodTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedBloodType = val),
                  decoration: InputDecoration(
                    labelText: 'blood_type'.tr(),
                    prefixIcon: const Icon(Icons.bloodtype),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'date_of_birth'.tr(),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'select_date'.tr()
                          : _selectedDate!.toIso8601String().split('T')[0],
                      style: TextStyle(
                        color: _selectedDate == null
                            ? (isDarkMode ? Colors.white54 : Colors.grey)
                            : (isDarkMode ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    child: _isLoading
                        ? const CustomLoader(size: 20, color: Colors.white)
                        : Text('update_info'.tr()),
                  ),
                ),
                const SizedBox(height: 40),

                if (_isDonor) ...[
                  Text(
                    'donation_history'.tr(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DonationHistoryList(
                    history: _donationHistory,
                    isLoading: _isHistoryLoading,
                  ),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Card Widgets ──────────────────────────────────────────────────────────

  Widget _buildPriorityCard(bool isDark) {
    final isPending = _priorityStatus == 'pending';
    final isApproved = _priorityStatus == 'high';
    final isRejected = _priorityStatus == 'rejected';

    Color cardColor;
    IconData cardIcon;
    String cardTitle;
    String cardSubtitle;

    if (isApproved) {
      cardColor = AppTheme.primaryRed;
      cardIcon = Icons.star_rounded;
      cardTitle = 'High Priority Approved ⭐';
      cardSubtitle = 'You have been granted high priority status by an admin.';
    } else if (isPending) {
      cardColor = Colors.orange;
      cardIcon = Icons.hourglass_top_rounded;
      cardTitle = 'Request Pending Review';
      cardSubtitle = 'Your priority request is awaiting admin approval.';
    } else if (isRejected) {
      cardColor = Colors.grey;
      cardIcon = Icons.cancel_outlined;
      cardTitle = 'Request Rejected';
      cardSubtitle = 'Your previous request was rejected. You may submit a new one.';
    } else {
      cardColor = Colors.blue;
      cardIcon = Icons.priority_high_rounded;
      cardTitle = 'Request High Priority';
      cardSubtitle =
          'If you urgently need blood, request high-priority status for faster assistance.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(cardIcon, color: cardColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: cardColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cardSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isApproved && !isPending) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRequestingPriority ? null : _requestHighPriority,
                icon: _isRequestingPriority
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isRequestingPriority ? 'Submitting...' : 'Request High Priority',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEligibilityCard(bool isDark) {
    final statusColor = _isDeferred ? Colors.orange : Colors.green;
    final statusIcon = _isDeferred ? Icons.timer : Icons.check_circle;
    final statusText = _isDeferred ? 'donation_deferral_notice'.tr() : 'ready_to_donate'.tr();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'eligibility_status'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isDeferred && _remainingTime.isNotEmpty) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _calculateProgress(),
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Text(
              _remainingTime,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                  fontFamily: 'monospace'),
            ),
            Text(
              'time_remaining'.tr(),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
