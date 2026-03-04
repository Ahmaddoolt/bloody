// file: lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Static design-token shortcuts.
///
/// These are semantic aliases over [AppTheme] raw values. Use these in
/// reference and shared widgets so you only update colors in one place.
///
/// For context-aware (light / dark adaptive) colors, use [Theme.of(context)]
/// directly instead of these constants.
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color accent = AppTheme.primaryRed;
  static const Color accentDark = AppTheme.darkRed;
  static const Color accentLight = AppTheme.accentPink;

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background = AppTheme.darkBackground;
  static const Color surface = AppTheme.darkSurface;
  static const Color surfaceVariant = AppTheme.darkCard;
  static const Color divider = AppTheme.darkDivider;

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFEDE0E0);
  static const Color textSecondary = Color(0xFFB0A4A4);
  static const Color textTertiary = AppTheme.darkHint;
}
