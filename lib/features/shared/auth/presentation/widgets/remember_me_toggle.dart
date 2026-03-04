import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

class RememberMeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const RememberMeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: AppColors.accent,
            onChanged: (val) => onChanged(val ?? true),
          ),
          Text(
            'remember_me'.tr(),
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
