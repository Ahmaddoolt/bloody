import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../utils/auth_validators.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool showStrengthIndicator;
  final TextInputAction textInputAction;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.showStrengthIndicator = false,
    this.textInputAction = TextInputAction.next,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;
  double _strength = 0.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconColor = colors.onSurface.withValues(alpha: 0.5);
    final dividerColor = colors.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: widget.showStrengthIndicator
              ? (val) => setState(() => _strength = AuthValidators.passwordStrength(val))
              : null,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(Icons.lock_outline, color: iconColor),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: iconColor,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
          ),
        ),
        if (widget.showStrengthIndicator) ...[
          SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _strength,
              minHeight: 4,
              backgroundColor: dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            _strengthLabel,
            style: TextStyle(fontSize: 12, color: _strengthColor),
          ),
        ],
      ],
    );
  }

  Color get _strengthColor {
    if (_strength <= 0.3) return Colors.red;
    if (_strength <= 0.6) return Colors.orange;
    return Colors.green;
  }

  String get _strengthLabel {
    if (_strength <= 0.0) return '';
    if (_strength <= 0.3) return 'password_strength_weak'.tr();
    if (_strength <= 0.6) return 'password_strength_medium'.tr();
    return 'password_strength_strong'.tr();
  }
}
