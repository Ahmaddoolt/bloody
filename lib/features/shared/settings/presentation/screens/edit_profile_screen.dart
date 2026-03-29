import 'package:bloody/core/constants/app_constants.dart';
import 'package:bloody/core/theme/app_colors.dart';
import 'package:bloody/core/theme/app_theme.dart';
import 'package:bloody/core/widgets/app_loading_indicator.dart';
import 'package:bloody/features/shared/settings/presentation/providers/profile_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final String username;
  final String phone;
  final String? bloodType;
  final String? city;
  final String? birthDate;
  final String? bloodRequestReason;

  const EditProfileScreen({
    super.key,
    required this.username,
    required this.phone,
    this.bloodType,
    this.city,
    this.birthDate,
    this.bloodRequestReason,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bloodRequestReasonController = TextEditingController();
  String? _selectedBloodType;
  String? _selectedCity;
  DateTime? _selectedDate;
  bool _isLoading = false;

  String get _userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.username;
    _phoneController.text = widget.phone;
    _bloodRequestReasonController.text = widget.bloodRequestReason ?? '';
    _selectedBloodType = widget.bloodType;
    _selectedCity = widget.city;
    if (widget.birthDate != null) {
      _selectedDate = DateTime.tryParse(widget.birthDate!);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _bloodRequestReasonController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    final success = await ref.read(profileProvider.notifier).updateProfile(
          userId: _userId,
          username: _usernameController.text.trim(),
          phone: _phoneController.text.trim(),
          bloodType: _selectedBloodType,
          city: _selectedCity,
          birthDate: _selectedDate?.toIso8601String().split('T')[0],
        );

    // Save blood request reason directly if changed
    final reason = _bloodRequestReasonController.text.trim();
    if (reason != (widget.bloodRequestReason ?? '')) {
      try {
        await Supabase.instance.client.from('profiles').update({
          'blood_request_reason': reason.isEmpty ? null : reason
        }).eq('id', _userId);
      } on PostgrestException catch (error) {
        if (error.code != '42703') rethrow;
      }
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            success ? 'profile_updated'.tr() : 'error_updating_profile'.tr()),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ));
      if (success) Navigator.pop(context);
    }
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldFill =
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent, width: 2),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('edit_profile'.tr()),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(
              controller: _usernameController,
              label: 'username'.tr(),
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'phone_number'.tr(),
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              dropdownColor: isDark ? AppTheme.darkCard : colorScheme.surface,
              decoration: InputDecoration(
                labelText: 'city_label'.tr(),
                prefixIcon: const Icon(Icons.location_city_rounded),
                filled: true,
                fillColor: fieldFill,
                border: enabledBorder,
                enabledBorder: enabledBorder,
                focusedBorder: focusedBorder,
              ),
              items: AppCities.syrianCities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.tr())))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCity = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedBloodType,
              dropdownColor: isDark ? AppTheme.darkCard : colorScheme.surface,
              decoration: InputDecoration(
                labelText: 'blood_type'.tr(),
                prefixIcon: const Icon(Icons.bloodtype_rounded),
                filled: true,
                fillColor: fieldFill,
                border: enabledBorder,
                enabledBorder: enabledBorder,
                focusedBorder: focusedBorder,
              ),
              items: AppCities.bloodTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedBloodType = val),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: fieldFill,
              leading: const Icon(Icons.cake_rounded),
              title: Text(_selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : 'date_of_birth'.tr()),
              trailing: const Icon(Icons.edit_rounded),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bloodRequestReasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'blood_request_reason_label'.tr(),
                prefixIcon: const Icon(Icons.bloodtype_rounded),
                filled: true,
                fillColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const AppLoadingIndicator(
                        size: 20,
                        strokeWidth: 2,
                        color: Colors.white,
                      )
                    : Text('save_changes'.tr(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }
}
