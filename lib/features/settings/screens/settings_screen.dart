// file: lib/features/settings/screens/settings_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_loader.dart';
import '../../auth/screens/login_screen.dart'; // Added Import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _phoneController = TextEditingController();

  String? _selectedBloodType;
  DateTime? _selectedDate;

  bool _isLoading = false;
  // We determine toggle state based on current locale
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
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
          if (_bloodTypes.contains(data['blood_type'])) {
            _selectedBloodType = data['blood_type'];
          }
          if (data['birth_date'] != null) {
            _selectedDate = DateTime.tryParse(data['birth_date']);
          }
        });
      }
    } catch (e) {
      // Handle error silently or show snackbar
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
        'phone': _phoneController.text.trim(),
        'blood_type': _selectedBloodType,
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
          SnackBar(
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
      // 1. Sign out from Supabase
      await Supabase.instance.client.auth.signOut();

      // 2. Navigate to Login Screen and clear the stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false, // This removes all previous routes (MainLayout)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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

        return Scaffold(
          appBar: AppBar(title: Text('settings'.tr())),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      setState(() {}); // Force rebuild
                    },
                  ),
                ),
                const Divider(height: 40),
                Text(
                  'my_info'.tr(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
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
                  value: _selectedBloodType,
                  dropdownColor:
                      isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.logout),
                    label: Text('log_out'.tr()),
                    onPressed:
                        _handleLogout, // FIXED: Calls correct logout function
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
