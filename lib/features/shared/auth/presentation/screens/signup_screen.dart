import 'package:bloody/core/constants/app_constants.dart';
import 'package:bloody/core/layout/main_layout.dart';
import 'package:bloody/core/services/fcm_service.dart';
import 'package:bloody/core/theme/app_colors.dart';
import 'package:bloody/core/widgets/app_loading_indicator.dart';
import 'package:bloody/core/theme/app_spacing.dart';
import 'package:bloody/features/donor/dashboard/presentation/providers/donor_profile_provider.dart';
import 'package:bloody/features/receiver/map_finder/presentation/providers/receiver_map_provider.dart';
import 'package:bloody/features/shared/auth/presentation/providers/auth_provider.dart';
import 'package:bloody/features/shared/settings/presentation/providers/profile_provider.dart';
import 'package:bloody/features/shared/auth/presentation/widgets/donor_rules_dialog.dart';
import 'package:bloody/features/shared/auth/presentation/widgets/password_field.dart';
import 'package:bloody/features/shared/auth/presentation/widgets/user_type_selector.dart';
import 'package:bloody/features/shared/auth/utils/auth_validators.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _scrollController = ScrollController();

  DateTime? _selectedDate;
  String? _selectedBloodType;
  String? _selectedCity;
  String _selectedType = 'receiver';

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onTypeChanged(String type) async {
    if (type == 'donor') {
      final confirmed = await showDonorRulesDialog(context);
      if (!confirmed) return;
    }
    setState(() => _selectedType = type);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCity == null) {
      _showError('city_required'.tr());
      return;
    }
    if (_selectedBloodType == null) {
      _showError('select_blood_error'.tr());
      return;
    }
    if (_selectedDate == null) {
      _showError('enter_dob_error'.tr());
      return;
    }

    final result = await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text,
          password: _passwordController.text,
          username: _usernameController.text,
          phone: _phoneController.text,
          userType: _selectedType,
          bloodType: _selectedBloodType!,
          city: _selectedCity!,
          birthDate: _selectedDate!,
        );

    if (!mounted) return;

    if (result.success) {
      if (_selectedType == 'receiver') {
        await FcmService.initialize();
        await FcmService.notifyDonorsInCity(
          city: _selectedCity!,
          bloodType: _selectedBloodType!,
        );
      }
      if (!mounted) return;

      ref.invalidate(receiverMapProvider);
      ref.invalidate(donorProfileProvider);
      ref.invalidate(profileProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('account_created'.tr()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainLayout(userType: _selectedType)),
        (route) => false,
      );
    } else {
      _showError(result.error ?? 'signup_failed'.tr());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('create_account'.tr()),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: AppSpacing.page.copyWith(top: 16, bottom: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          UserTypeSelector(
                            selectedType: _selectedType,
                            onChanged: isLoading ? (_) {} : _onTypeChanged,
                          ),
                          const SizedBox(height: 16),
                          _InputField(
                            controller: _emailController,
                            label: 'email'.tr(),
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: AuthValidators.email,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _usernameController,
                            label: 'username'.tr(),
                            icon: Icons.person_outline,
                            validator: AuthValidators.username,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 8),
                          PasswordField(
                            controller: _passwordController,
                            label: 'password'.tr(),
                            validator: AuthValidators.password,
                            showStrengthIndicator: true,
                          ),
                          const SizedBox(height: 8),
                          PasswordField(
                            controller: _confirmPasswordController,
                            label: 'confirm_password'.tr(),
                            validator: (val) => AuthValidators.confirmPassword(
                              val,
                              _passwordController.text,
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _phoneController,
                            label: 'phone_number'.tr(),
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: AuthValidators.phone,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 8),
                          _DropdownField(
                            label: 'city_label'.tr(),
                            icon: Icons.location_city,
                            value: _selectedCity,
                            items: AppCities.syrianCities,
                            onChanged: isLoading
                                ? null
                                : (val) => setState(() => _selectedCity = val),
                            validator: (val) =>
                                val == null ? 'city_required'.tr() : null,
                          ),
                          const SizedBox(height: 8),
                          _DatePickerField(
                            label: 'date_of_birth'.tr(),
                            selectedDate: _selectedDate,
                            onTap: isLoading ? null : _pickDate,
                          ),
                          const SizedBox(height: 8),
                          _DropdownField(
                            label: 'blood_type'.tr(),
                            icon: Icons.bloodtype,
                            value: _selectedBloodType,
                            items: AppCities.bloodTypes,
                            translateItems: false,
                            onChanged: isLoading
                                ? null
                                : (val) =>
                                    setState(() => _selectedBloodType = val),
                            validator: (val) =>
                                val == null ? 'select_blood_error'.tr() : null,
                          ),
                          const SizedBox(height: 20),
                          _PrimaryButton(
                            label: 'sign_up_enter'.tr(),
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _signUp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: colorScheme.onSurface.withValues(alpha: 0.5)),
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
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final bool translateItems;

  const _DropdownField({
    required this.label,
    required this.icon,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.translateItems = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((item) => DropdownMenuItem(
              value: item, child: Text(translateItems ? item.tr() : item)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: colorScheme.onSurface.withValues(alpha: 0.5)),
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
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final VoidCallback? onTap;

  const _DatePickerField({
    required this.label,
    this.selectedDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.calendar_today,
              color: colorScheme.onSurface.withValues(alpha: 0.5)),
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
            borderSide: BorderSide(color: AppColors.accent, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          selectedDate == null
              ? 'select_date'.tr()
              : selectedDate!.toIso8601String().split('T')[0],
          style: TextStyle(
            color: selectedDate == null
                ? colorScheme.onSurface.withValues(alpha: 0.4)
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null
          ? null
          : (_) => setState(() => _scale = 0.97),
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() => _scale = 1.0);
              widget.onPressed?.call();
            },
      onTapCancel:
          widget.onPressed == null ? null : () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: widget.isLoading
                ? const AppLoadingIndicator(
                    size: 20,
                    strokeWidth: 2,
                    color: Colors.white,
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
