// file: lib/shared/centers_list/presentation/widgets/admin_center_dialog.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/custom_loader.dart';
import '../screens/location_picker_screen.dart';

class AdminCenterDialog extends StatefulWidget {
  final Map<String, dynamic>? center;
  final VoidCallback onSuccess;

  const AdminCenterDialog({super.key, this.center, required this.onSuccess});

  @override
  State<AdminCenterDialog> createState() => _AdminCenterDialogState();
}

class _AdminCenterDialogState extends State<AdminCenterDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addrCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  late TextEditingController _emailCtrl;

  bool _isSaving = false;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.center?['name'] ?? '');
    _addrCtrl = TextEditingController(text: widget.center?['address'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.center?['phone'] ?? '');
    _latCtrl = TextEditingController(text: widget.center?['latitude']?.toString() ?? '');
    _lngCtrl = TextEditingController(text: widget.center?['longitude']?.toString() ?? '');
    _emailCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    LatLng? initialPos;
    final double? lat = double.tryParse(_latCtrl.text);
    final double? lng = double.tryParse(_lngCtrl.text);
    if (lat != null && lng != null) initialPos = LatLng(lat, lng);

    final LatLng? result = await Navigator.push(context,
        MaterialPageRoute(builder: (_) => LocationPickerScreen(initialLocation: initialPos)));

    if (result != null) {
      setState(() {
        _latCtrl.text = result.latitude.toStringAsFixed(6);
        _lngCtrl.text = result.longitude.toStringAsFixed(6);
        _isGeocoding = true;
      });
      try {
        final placemarks = await placemarkFromCoordinates(result.latitude, result.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final addr = [p.street, p.subLocality, p.locality, p.country]
              .where((e) => e != null && e!.isNotEmpty)
              .join(', ');
          if (_addrCtrl.text.isEmpty || widget.center == null) _addrCtrl.text = addr;
        }
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isGeocoding = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final supabase = Supabase.instance.client;

    try {
      String? adminId;
      if (_emailCtrl.text.isNotEmpty) {
        final user = await supabase
            .from('profiles')
            .select('id')
            .eq('email', _emailCtrl.text.trim())
            .maybeSingle();
        if (user != null) {
          adminId = user['id'];
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('email_not_found'.tr())));
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'latitude': double.tryParse(_latCtrl.text),
        'longitude': double.tryParse(_lngCtrl.text),
      };
      if (adminId != null) data['admin_id'] = adminId;

      if (widget.center == null) {
        await supabase.from('centers').insert(data);
      } else {
        await supabase.from('centers').update(data).eq('id', widget.center!['id']);
      }

      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('success'.tr()),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('error_saving'.tr()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog title
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_hospital_rounded,
                          color: AppTheme.primaryRed, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.center == null ? 'add_center'.tr() : 'edit_center'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Section: Info ─────────────────────
                _SectionLabel(label: 'my_info'.tr(), isDark: isDark),
                const SizedBox(height: 10),
                _buildField(
                  context,
                  controller: _nameCtrl,
                  label: 'name'.tr(),
                  icon: Icons.business_rounded,
                  isDark: isDark,
                  validator: (v) => v!.isEmpty ? 'required'.tr() : null,
                ),
                const SizedBox(height: 12),
                _buildField(
                  context,
                  controller: _phoneCtrl,
                  label: 'phone_number'.tr(),
                  icon: Icons.phone_rounded,
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 20),

                // ── Section: Location ─────────────────
                _SectionLabel(label: 'address'.tr(), isDark: isDark),
                const SizedBox(height: 10),

                // Map picker button
                InkWell(
                  onTap: _pickLocation,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(isDark ? 0.12 : 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.25), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.map_rounded, color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'select_on_map'.tr(),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        // Lat/lng preview
                        if (_latCtrl.text.isNotEmpty)
                          Text(
                            '${double.tryParse(_latCtrl.text)?.toStringAsFixed(3)}, '
                            '${double.tryParse(_lngCtrl.text)?.toStringAsFixed(3)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_isGeocoding)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2, color: AppTheme.primaryRed),
                  ),
                const SizedBox(height: 10),
                _buildField(
                  context,
                  controller: _addrCtrl,
                  label: 'address'.tr(),
                  icon: Icons.location_on_rounded,
                  isDark: isDark,
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

                // ── Section: Manager ──────────────────
                _SectionLabel(label: 'assign_manager_optional'.tr(), isDark: isDark),
                const SizedBox(height: 10),
                _buildField(
                  context,
                  controller: _emailCtrl,
                  label: 'manager_email'.tr(),
                  icon: Icons.security_rounded,
                  isDark: isDark,
                  iconColor: Colors.orange,
                  keyboardType: TextInputType.emailAddress,
                  helperText: 'user_must_sign_up'.tr(),
                ),

                const SizedBox(height: 28),

                // ── Actions ────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('cancel'.tr(),
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 3,
                          shadowColor: AppTheme.primaryRed.withOpacity(0.35),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CustomLoader(size: 20, color: Colors.white))
                            : Text('save'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    Color? iconColor,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    final color = iconColor ?? AppTheme.primaryRed;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, color: color, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.15),
              width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withOpacity(0.6), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 3,
          height: 14,
          decoration:
              BoxDecoration(color: AppTheme.primaryRed, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? Colors.grey[400] : Colors.grey[600])),
    ]);
  }
}
