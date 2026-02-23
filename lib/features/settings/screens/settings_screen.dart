// file: lib/features/settings/screens/settings_screen.dart
import 'dart:async';

import 'package:bloody/features/settings/screens/widgets/donation_history_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_loader.dart';
import '../../auth/screens/login_screen.dart';

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

  bool get _isArabic => context.locale.languageCode == 'ar';

  final String _userId = Supabase.instance.client.auth.currentUser!.id;
  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

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
        }
      } else {
        if (mounted) {
          setState(() {
            _remainingTime = _formatDuration(remaining);
          });
        }
      }
    });
  }

  Future<void> _loadProfile() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _userId)
          .single();

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

          if (_isDonor) {
            _fetchDonationHistory();
            if (data['last_donation_date'] != null) {
              _lastDonationDate = DateTime.parse(data['last_donation_date']);
              _nextEligibleDate =
                  _lastDonationDate!.add(const Duration(days: 90));

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
    } catch (e) {
      debugPrint("Error loading profile: $e");
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
    } catch (e) {
      debugPrint("Error fetching history: $e");
      if (mounted) setState(() => _isHistoryLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final updates = {
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'blood_type': _selectedBloodType,
        'city': _selectedCity,
        'birth_date': _selectedDate?.toIso8601String().split('T')[0],
      };

      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', _userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_updated'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error updating profile'),
              backgroundColor: Colors.red),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error logging out'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, currentMode, child) {
        final bool isDarkMode = currentMode == ThemeMode.dark;
        final dropdownColor =
            isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;

        return Scaffold(
          appBar: AppBar(
            title: Text('settings'.tr()),
            actions: [
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

                Text(
                  'app_settings'.tr(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
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
                      AppTheme.saveTheme(
                          val ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.language, color: AppTheme.primaryRed),
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
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),

                // Username Field (NEW & TRANSLATED)
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

                // City Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  dropdownColor: dropdownColor,
                  items: _syrianCities
                      .map((city) =>
                          DropdownMenuItem(value: city, child: Text(city.tr())))
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
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
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
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildEligibilityCard(bool isDark) {
    Color statusColor = _isDeferred ? Colors.orange : Colors.green;
    IconData statusIcon = _isDeferred ? Icons.timer : Icons.check_circle;
    String statusText =
        _isDeferred ? "donation_deferral_notice".tr() : "ready_to_donate".tr();

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
                      "eligibility_status".tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
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
              "time_remaining".tr(),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ]
        ],
      ),
    );
  }

  double _calculateProgress() {
    if (_lastDonationDate == null || _nextEligibleDate == null) return 0;
    final totalDuration =
        _nextEligibleDate!.difference(_lastDonationDate!).inSeconds;
    final elapsed = DateTime.now().difference(_lastDonationDate!).inSeconds;
    if (totalDuration <= 0) return 1.0;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }
}
