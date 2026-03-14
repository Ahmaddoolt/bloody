import 'package:bloody/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LanguageSwitcher extends StatelessWidget {
  final String currentLanguage;
  final VoidCallback onToggle;

  const LanguageSwitcher({
    super.key,
    required this.currentLanguage,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = currentLanguage == 'ar';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
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
          child: Icon(Icons.language, color: AppTheme.primaryRed, size: 22),
        ),
        title: Text(
          isArabic ? 'العربية' : 'English',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          isArabic ? 'Tap to switch to English' : 'اضغط للتبديل إلى العربية',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : Colors.black45,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isArabic ? 'AR' : 'EN',
            style: TextStyle(
              color: AppTheme.primaryRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: onToggle,
      ),
    );
  }
}
