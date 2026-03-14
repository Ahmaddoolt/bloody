import 'package:bloody/core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ThemeSwitcher extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const ThemeSwitcher({
    super.key,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: AppTheme.primaryRed,
            size: 22,
          ),
        ),
        title: Text(
          isDarkMode ? 'theme_dark_desc'.tr() : 'theme_light_desc'.tr(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        trailing: Switch(
          value: isDarkMode,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primaryRed,
        ),
      ),
    );
  }
}
