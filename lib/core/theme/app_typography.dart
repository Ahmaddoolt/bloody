// file: lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';

/// Shared text-style constants.
///
/// All styles are colour-agnostic (no [TextStyle.color] set here).
/// Tint them at the call site with [TextStyle.copyWith].
class AppTypography {
  AppTypography._();

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
}
