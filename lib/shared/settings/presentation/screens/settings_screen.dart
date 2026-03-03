// file: lib/shared/settings/presentation/screens/settings_screen.dart
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../data/settings_service.dart';
import 'donation_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _service = SettingsService();

  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();

  String? _selectedBloodType;
  String? _selectedCity;
  DateTime? _selectedDate;

  bool _isLoading = false;

  bool _isDeferred = false;
  DateTime? _lastDonationDate;
  DateTime? _nextEligibleDate;
  Timer? _countdownTimer;
  String _remainingTime = '';

  bool _isDonor = true;
  String _priorityStatus = 'none';

  bool _isAvailable = true;
  bool _isTogglingAvailability = false;

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
    'Rif Dimashq',
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
    return total <= 0 ? 1.0 : (elapsed / total).clamp(0.0, 1.0);
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    final data = await _service.getProfile(_userId);
    if (data != null && mounted) {
      setState(() {
        _phoneController.text = data['phone'] ?? '';
        _usernameController.text = data['username'] ?? '';
        if (_bloodTypes.contains(data['blood_type'])) _selectedBloodType = data['blood_type'];
        if (_syrianCities.contains(data['city'])) _selectedCity = data['city'];
        if (data['birth_date'] != null) _selectedDate = DateTime.tryParse(data['birth_date']);

        _isDonor = data['user_type'] == 'donor';
        _priorityStatus = data['priority_status'] ?? 'none';
        _isAvailable = data['is_available'] ?? true;

        if (_isDonor && data['last_donation_date'] != null) {
          _lastDonationDate = DateTime.parse(data['last_donation_date']);
          _nextEligibleDate = _lastDonationDate!.add(const Duration(days: 90));
          _isDeferred = _nextEligibleDate!.isAfter(DateTime.now());
          if (_isDeferred) _startCountdownTimer();
        }
      });
    }
  }

  Future<void> _handleAvailabilityToggle(bool newValue) async {
    if (_isTogglingAvailability) return;
    setState(() {
      _isAvailable = newValue;
      _isTogglingAvailability = true;
    });
    final result = await _service.toggleAvailability(userId: _userId, isAvailable: newValue);
    if (!mounted) return;
    if (result == null) {
      setState(() => _isAvailable = !newValue);
      _showSnack('availability_update_error'.tr(), Colors.red);
    } else {
      _showSnack(
        newValue ? 'status_online'.tr() : 'status_offline'.tr(),
        newValue ? const Color(0xFF2E7D32) : Colors.grey[700]!,
      );
    }
    setState(() => _isTogglingAvailability = false);
  }

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
    final success = await _service.updateProfile(
      userId: _userId,
      username: _usernameController.text.trim(),
      phone: _phoneController.text.trim(),
      bloodType: _selectedBloodType,
      city: _selectedCity,
      birthDate: _selectedDate?.toIso8601String().split('T')[0],
    );
    if (mounted) {
      setState(() => _isLoading = false);
      _showSnack(
        success ? 'profile_updated'.tr() : 'error_updating_profile'.tr(),
        success ? const Color(0xFF2E7D32) : Colors.red,
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('log_out'.tr()),
        content: Text('logout_confirm'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr(), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('log_out'.tr())),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;
        final dropdownColor = isDark ? AppTheme.darkCard : Colors.white;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF5F6FA),
          appBar: _buildAppBar(isDark),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header card (sits flush under the appbar)
                _buildProfileHeader(isDark),
                const SizedBox(height: 20),

                // Status cards
                if (_isDonor) ...[
                  _buildEligibilityCard(isDark),
                  const SizedBox(height: 12),
                  _buildAvailabilityCard(isDark),
                  const SizedBox(height: 20),
                ],
                if (!_isDonor) ...[
                  _buildPriorityStatusCard(isDark),
                  const SizedBox(height: 20),
                ],

                _buildSectionHeader('app_settings'.tr()),
                const SizedBox(height: 12),
                _buildPreferencesCard(isDark),
                const SizedBox(height: 24),

                _buildSectionHeader('my_info'.tr()),
                const SizedBox(height: 12),
                _buildInfoCard(isDark, dropdownColor),
                const SizedBox(height: 24),

                _buildSaveButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryRed,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      title: Text(
        'settings'.tr(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      actions: [
        // Donation history — donors only
        if (_isDonor)
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DonationHistoryScreen(userId: _userId)),
            ),
            icon: const Icon(Icons.volunteer_activism_rounded, color: Colors.white),
            tooltip: 'donation_history'.tr(),
          ),
        IconButton(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          tooltip: 'Notifications',
        ),
        IconButton(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          tooltip: 'log_out'.tr(),
        ),
        const SizedBox(width: 4),
      ],
      // Rounded bottom corners so it blends into the profile card
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    );
  }

  // ─── Profile header card ───────────────────────────────────────────────────

  Widget _buildProfileHeader(bool isDark) {
    final username = _usernameController.text.isNotEmpty
        ? _usernameController.text
        : Supabase.instance.client.auth.currentUser?.email?.split('@')[0] ?? '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryRed, AppTheme.darkRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Blood type chip
                    _SmallChip(
                      label: _selectedBloodType ?? '—',
                      icon: Icons.bloodtype_rounded,
                      color: AppTheme.primaryRed,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    // City chip
                    if (_selectedCity != null)
                      _SmallChip(
                        label: _selectedCity!,
                        icon: Icons.location_on_rounded,
                        color: Colors.blue.shade700,
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isDonor ? AppTheme.primaryRed.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    _isDonor ? AppTheme.primaryRed.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Text(
              _isDonor ? 'donor'.tr() : 'receiver'.tr(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _isDonor ? AppTheme.primaryRed : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Eligibility card ──────────────────────────────────────────────────────

  Widget _buildEligibilityCard(bool isDark) {
    final color = _isDeferred ? const Color(0xFFE65100) : const Color(0xFF2E7D32);
    final icon = _isDeferred ? Icons.hourglass_bottom_rounded : Icons.check_circle_rounded;
    final label = _isDeferred ? 'donation_deferral_notice'.tr() : 'ready_to_donate'.tr();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'eligibility_status'.tr(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 3),
                  Text(label,
                      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
            ],
          ),
          if (_isDeferred && _remainingTime.isNotEmpty) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _calculateProgress(),
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Center(
                child: Text(
                  _remainingTime,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('time_remaining'.tr(), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ],
      ),
    );
  }

  // ─── Availability card ─────────────────────────────────────────────────────

  Widget _buildAvailabilityCard(bool isDark) {
    const activeColor = Color(0xFF2E7D32);
    const inactiveColor = Color(0xFF757575);
    final color = _isAvailable ? activeColor : inactiveColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.12 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(
                  _isAvailable ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
                  color: color,
                  size: 26,
                ),
              ),
              if (_isAvailable)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: isDark ? AppTheme.darkCard : Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable ? 'availability_online'.tr() : 'availability_offline'.tr(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15, color: color, height: 1.4),
                ),
                const SizedBox(height: 3),
                Text(
                  _isAvailable ? 'availability_online_desc'.tr() : 'availability_offline_desc'.tr(),
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            height: 48,
            child: Center(
              child: _isTogglingAvailability
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: color))
                  : Switch(
                      value: _isAvailable,
                      activeColor: activeColor,
                      activeTrackColor: activeColor.withOpacity(0.3),
                      inactiveThumbColor: inactiveColor,
                      inactiveTrackColor: inactiveColor.withOpacity(0.2),
                      onChanged: _handleAvailabilityToggle,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Priority status card ──────────────────────────────────────────────────

  Widget _buildPriorityStatusCard(bool isDark) {
    final isPending = _priorityStatus == 'pending';
    final isApproved = _priorityStatus == 'high';
    final isRejected = _priorityStatus == 'rejected';

    final Color color;
    final IconData icon;
    final String title;
    final String subtitle;

    if (isApproved) {
      color = AppTheme.primaryRed;
      icon = Icons.star_rounded;
      title = 'priority_approved'.tr();
      subtitle = 'priority_approved_desc'.tr();
    } else if (isPending) {
      color = const Color(0xFFE65100);
      icon = Icons.hourglass_top_rounded;
      title = 'priority_pending'.tr();
      subtitle = 'priority_pending_desc'.tr();
    } else if (isRejected) {
      color = const Color(0xFF616161);
      icon = Icons.cancel_outlined;
      title = 'priority_rejected'.tr();
      subtitle = 'priority_rejected_desc'.tr();
    } else {
      color = Colors.blue.shade700;
      icon = Icons.shield_outlined;
      title = 'priority_none'.tr();
      subtitle = 'priority_none_desc'.tr();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.admin_panel_settings_outlined, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('admin_managed'.tr(),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── Preferences card ──────────────────────────────────────────────────────

  Widget _buildPreferencesCard(bool isDark) {
    final isDarkMode = AppTheme.themeNotifier.value == ThemeMode.dark;
    return Container(
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          _buildToggleRow(
            icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconColor: isDarkMode ? const Color(0xFF90CAF9) : const Color(0xFFFFB74D),
            label: 'dark_mode'.tr(),
            subtitle: isDarkMode ? 'theme_dark_desc'.tr() : 'theme_light_desc'.tr(),
            value: isDarkMode,
            onChanged: (val) => AppTheme.saveTheme(val ? ThemeMode.dark : ThemeMode.light),
          ),
          Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12)),
          _buildToggleRow(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF42A5F5),
            label: 'arabic_lang'.tr(),
            subtitle: _isArabic ? 'العربية مفعّلة' : 'English enabled',
            value: _isArabic,
            onChanged: (val) async {
              await context.setLocale(val ? const Locale('ar') : const Locale('en'));
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = AppTheme.themeNotifier.value == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87)),
              Text(subtitle,
                  style:
                      TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ]),
          ),
          Switch(value: value, activeColor: AppTheme.primaryRed, onChanged: onChanged),
        ],
      ),
    );
  }

  // ─── Info card ─────────────────────────────────────────────────────────────

  Widget _buildInfoCard(bool isDark, Color dropdownColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          _buildTextField(
              controller: _usernameController, label: 'username'.tr(), icon: Icons.person_rounded),
          const SizedBox(height: 16),
          _buildTextField(
              controller: _phoneController,
              label: 'phone_number'.tr(),
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            dropdownColor: dropdownColor,
            decoration: InputDecoration(
              labelText: 'City',
              prefixIcon: const Icon(Icons.location_city_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items:
                _syrianCities.map((c) => DropdownMenuItem(value: c, child: Text(c.tr()))).toList(),
            onChanged: (val) => setState(() => _selectedCity = val),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedBloodType,
            dropdownColor: dropdownColor,
            decoration: InputDecoration(
              labelText: 'blood_type'.tr(),
              prefixIcon: const Icon(Icons.bloodtype_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) => setState(() => _selectedBloodType = val),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'date_of_birth'.tr(),
                prefixIcon: const Icon(Icons.calendar_today_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: Text(
                _selectedDate == null
                    ? 'select_date'.tr()
                    : _selectedDate!.toIso8601String().split('T')[0],
                style: TextStyle(
                    color: _selectedDate == null
                        ? (isDark ? Colors.white38 : Colors.grey[500])
                        : null),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _updateProfile,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.save_rounded, size: 20),
        label: Text('update_info'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: AppTheme.primaryRed.withOpacity(0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ─── Section header ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    final isDark = AppTheme.themeNotifier.value == ThemeMode.dark;
    return Row(children: [
      Container(
          width: 4,
          height: 20,
          decoration:
              BoxDecoration(color: AppTheme.primaryRed, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87)),
    ]);
  }

  BoxDecoration _cardDecoration(bool isDark) => BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

// ── Helper chip widget ────────────────────────────────────────────────────────

class _SmallChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SmallChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
