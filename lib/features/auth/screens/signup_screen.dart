// file: lib/features/auth/screens/signup_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/layout/main_layout.dart'; // Import MainLayout
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_loader.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Date State
  DateTime? _selectedDate;

  String? _selectedBloodType;
  String _selectedType = 'receiver';
  bool _isLoading = false;

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

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showDonorRules() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text("donor_eligibility".tr()),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("donor_rules_intro".tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _RuleItem(text: "rule_age".tr()),
              _RuleItem(text: "rule_weight".tr()),
              _RuleItem(text: "rule_tattoos".tr()),
              _RuleItem(text: "rule_health".tr()),
              _RuleItem(text: "rule_travel".tr()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedType = 'receiver');
              Navigator.pop(ctx);
            },
            child: FittedBox(
              child: Text("do_not_qualify".tr(),
                  style: const TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text("confirm_agree".tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTypeChanged(String type) {
    setState(() => _selectedType = type);
    if (type == 'donor') {
      _showDonorRules();
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBloodType == null) {
      _showError('select_blood_error'.tr());
      return;
    }
    if (_selectedDate == null) {
      _showError('enter_dob_error'.tr());
      return;
    }

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      final position = await _getCurrentLocation();

      final cleanEmail = _emailController.text.trim();
      final cleanPassword = _passwordController.text.trim();
      final cleanPhone = _phoneController.text.trim();
      final dobString = _selectedDate!.toIso8601String().split('T')[0];

      // 1. Sign Up
      final AuthResponse res = await supabase.auth.signUp(
        email: cleanEmail,
        password: cleanPassword,
      );

      // 2. Insert Profile Data
      if (res.user != null) {
        await supabase.from('profiles').insert({
          'id': res.user!.id,
          'email': cleanEmail,
          'phone': cleanPhone,
          'user_type': _selectedType,
          'blood_type': _selectedBloodType, // Critical data point
          'latitude': position?.latitude,
          'longitude': position?.longitude,
          'birth_date': dobString,
          'points': 0,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('account_created'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          // 3. Force Navigation to Home directly to avoid "Stuck" state
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => MainLayout(userType: _selectedType),
            ),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text("create_account".tr())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeCard(
                        'receiver',
                        'i_need_blood'.tr(),
                        Icons.local_hospital,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTypeCard(
                        'donor',
                        'i_donate'.tr(),
                        Icons.volunteer_activism,
                        isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'required'.tr() : null,
                  decoration: InputDecoration(
                    labelText: 'email_username'.tr(),
                    hintText: 'enter_valid_email'.tr(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.length < 6)
                      return 'password_error'.tr();
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'password'.tr(),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (val) =>
                      val!.isEmpty ? 'phone_required'.tr() : null,
                  decoration: InputDecoration(
                    labelText: 'phone_number'.tr(),
                    prefixIcon: const Icon(Icons.phone),
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
                            ? (isDark ? Colors.white54 : Colors.grey.shade600)
                            : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedBloodType,
                  dropdownColor:
                      isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  items: _bloodTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedBloodType = val),
                  decoration: InputDecoration(
                    labelText: 'blood_type'.tr(),
                    prefixIcon: const Icon(Icons.bloodtype),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const CustomLoader(size: 20, color: Colors.white)
                      : Text('sign_up_enter'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    String type,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedType == type;
    final bgColor = isSelected
        ? AppTheme.primaryRed
        : (isDark ? const Color(0xFF2C2C2C) : Colors.white);
    final borderColor = isSelected
        ? AppTheme.primaryRed
        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300);
    final textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade700);
    final iconColor = isSelected
        ? Colors.white
        : (isDark ? Colors.grey.shade500 : Colors.grey);

    return GestureDetector(
      onTap: () => _onTypeChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryRed.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String text;
  const _RuleItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87))),
        ],
      ),
    );
  }
}
