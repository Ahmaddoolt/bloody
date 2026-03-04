// file: lib/core/theme/app_spacing.dart
import 'package:flutter/material.dart';

/// Shared spacing constants.
class AppSpacing {
  AppSpacing._();

  // ── Named edge-insets ────────────────────────────────────────────────────
  static const EdgeInsets page =
      EdgeInsets.symmetric(horizontal: 24, vertical: 20);
  static const EdgeInsets card = EdgeInsets.all(16);
  static const EdgeInsets section = EdgeInsets.symmetric(horizontal: 24);

  // ── Numeric values (dp) ──────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
