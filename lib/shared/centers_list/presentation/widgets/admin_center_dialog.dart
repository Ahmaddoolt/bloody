// file: lib/features/centers/widgets/admin_center_dialog.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_loader.dart';
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
    final double? currentLat = double.tryParse(_latCtrl.text);
    final double? currentLng = double.tryParse(_lngCtrl.text);
    if (currentLat != null && currentLng != null) {
      initialPos = LatLng(currentLat, currentLng);
    }

    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: initialPos),
      ),
    );

    if (result != null) {
      setState(() {
        _latCtrl.text = result.latitude.toStringAsFixed(6);
        _lngCtrl.text = result.longitude.toStringAsFixed(6);
        _isGeocoding = true;
      });

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final address = [p.street, p.subLocality, p.locality, p.country]
              .where((e) => e != null && e.isNotEmpty)
              .join(', ');

          if (_addrCtrl.text.isEmpty || widget.center == null) {
            _addrCtrl.text = address;
          }
        }
      } catch (e) {
        // Ignore errors
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("email_not_found".tr())),
            );
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      final data = {
        'name': _nameCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'latitude': double.tryParse(_latCtrl.text),
        'longitude': double.tryParse(_lngCtrl.text),
      };

      if (adminId != null) {
        data['admin_id'] = adminId;
      }

      if (widget.center == null) {
        await supabase.from('centers').insert(data);
      } else {
        await supabase.from('centers').update(data).eq('id', widget.center!['id']);
      }

      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Success")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("error_saving".tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDeco(BuildContext context, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05);
    final borderColor = isDark ? Colors.white10 : Colors.grey.withOpacity(0.1);

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return AlertDialog(
      title: Text(widget.center == null ? 'add_center'.tr() : 'edit_center'.tr()),
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("my_info".tr(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: labelColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  validator: (val) => val!.isEmpty ? 'required'.tr() : null,
                  decoration: _inputDeco(context, 'name'.tr(), Icons.business),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDeco(context, 'phone_number'.tr(), Icons.phone),
                ),
                const SizedBox(height: 24),
                Text("address".tr(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: labelColor)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _pickLocation,
                          icon: const Icon(Icons.map, color: Colors.blue),
                          label: Text("select_on_map".tr(),
                              style:
                                  const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      if (_isGeocoding) const LinearProgressIndicator(minHeight: 2),
                      TextFormField(
                        controller: _addrCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'address'.tr(),
                          prefixIcon: const Icon(Icons.location_on, size: 20, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text("assign_manager_optional".tr(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: labelColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDeco(context, 'manager_email'.tr(), Icons.security).copyWith(
                    helperText: 'user_must_sign_up'.tr(),
                    fillColor: Colors.orange.withOpacity(0.05),
                    prefixIcon: const Icon(Icons.security, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("cancel".tr(), style: const TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              // FIXED: Using CustomLoader here
              ? const SizedBox(
                  width: 20, height: 20, child: CustomLoader(size: 20, color: Colors.white))
              : Text("save".tr()),
        ),
      ],
    );
  }
}
