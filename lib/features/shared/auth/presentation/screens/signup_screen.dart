import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/layout/main_layout.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../references/button_patterns.dart';
import '../../data/auth_service.dart';
import '../../utils/auth_validators.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/donor_rules_dialog.dart';
import '../widgets/password_field.dart';
import '../widgets/user_type_selector.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedBloodType;
  String? _selectedCity;
  String _selectedType = 'receiver';
  bool _isLoading = false;

  late final AnimationController _animController;

  static const _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  static const _syrianCities = [
    'Damascus', 'Aleppo', 'Homs', 'Hama', 'Latakia', 'Tartus', 'Idlib',
    'Daraa', 'As-Suwayda', 'Quneitra', 'Deir ez-Zor', 'Al-Hasakah',
    'Raqqa', 'Rif Dimashq',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
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

    setState(() => _isLoading = true);

    final result = await AuthService.signUp(
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
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('account_created'.tr()),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainLayout(userType: _selectedType),
        ),
        (route) => false,
      );
    } else {
      _showError(result.error ?? 'signup_failed'.tr());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconColor = colors.onSurface.withValues(alpha: 0.5);
    final hintColor = colors.onSurface.withValues(alpha: 0.4);

    return Scaffold(
      appBar: AppBar(title: Text('create_account'.tr())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _staggered(
                  0,
                  child: UserTypeSelector(
                    selectedType: _selectedType,
                    onChanged: _onTypeChanged,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                _staggered(
                  1,
                  child: AuthTextField(
                    controller: _emailController,
                    label: 'email'.tr(),
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: AuthValidators.email,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                _staggered(
                  2,
                  child: AuthTextField(
                    controller: _usernameController,
                    label: 'username'.tr(),
                    prefixIcon: Icons.person_outline,
                    validator: AuthValidators.username,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                _staggered(
                  3,
                  child: PasswordField(
                    controller: _passwordController,
                    label: 'password'.tr(),
                    validator: AuthValidators.password,
                    showStrengthIndicator: true,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                _staggered(
                  4,
                  child: PasswordField(
                    controller: _confirmPasswordController,
                    label: 'confirm_password'.tr(),
                    validator: (val) => AuthValidators.confirmPassword(
                      val,
                      _passwordController.text,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                _staggered(
                  5,
                  child: AuthTextField(
                    controller: _phoneController,
                    label: 'phone_number'.tr(),
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: AuthValidators.phone,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                _staggered(
                  6,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCity,
                    dropdownColor: colors.surface,
                    items: _syrianCities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.tr())))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCity = val),
                    decoration: InputDecoration(
                      labelText: 'city_label'.tr(),
                      prefixIcon: Icon(Icons.location_city, color: iconColor),
                    ),
                    validator: (val) => val == null ? 'city_required'.tr() : null,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                _staggered(
                  7,
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'date_of_birth'.tr(),
                        prefixIcon: Icon(Icons.calendar_today, color: iconColor),
                      ),
                      child: Text(
                        _selectedDate == null
                            ? 'select_date'.tr()
                            : _selectedDate!.toIso8601String().split('T')[0],
                        style: TextStyle(
                          color: _selectedDate == null
                              ? hintColor
                              : colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                _staggered(
                  8,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedBloodType,
                    dropdownColor: colors.surface,
                    items: _bloodTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedBloodType = val),
                    decoration: InputDecoration(
                      labelText: 'blood_type'.tr(),
                      prefixIcon: Icon(Icons.bloodtype, color: iconColor),
                    ),
                    validator: (val) =>
                        val == null ? 'select_blood_error'.tr() : null,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                _staggered(
                  9,
                  child: AppButton(
                    label: 'sign_up_enter'.tr(),
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _signUp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _staggered(int index, {required Widget child}) {
    final begin = (index * 0.08).clamp(0.0, 0.6);
    final end = (begin + 0.4).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: _animController,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
