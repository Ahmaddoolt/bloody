// file: lib/core/theme/app_spacing.dart
import 'package:flutter/material.dart';

/// Spacing system following Apple Human Interface Guidelines.
/// Base unit: 4px. Primary scale uses multiples of 8px.
class AppSpacing {
  AppSpacing._();

  // ── Base unit ───────────────────────────────────────────────────
  static const double unit = 4.0;

  // ── Primary scale (use these 90% of the time) ───────────────────
  static const double xxs = 4.0; // Tight internal (icon to label)
  static const double xs = 8.0; // Compact elements
  static const double sm = 12.0; // Between related elements
  static const double md = 16.0; // Standard padding
  static const double lg = 24.0; // Section spacing
  static const double xl = 32.0; // Major section breaks
  static const double xxl = 48.0; // Screen-level breathing room
  static const double xxxl = 64.0; // Hero sections

  // ── Screen edge (Apple standard: 20px horizontal) ──────────────
  static const double screenEdge = 20.0;
  static const double screenEdgeWide = 24.0;

  // ── Named edge-insets ────────────────────────────────────────────
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: screenEdge);
  static const EdgeInsets pageVertical =
      EdgeInsets.symmetric(vertical: screenEdge);
  static const EdgeInsets card = EdgeInsets.all(16.0);
  static const EdgeInsets section =
      EdgeInsets.symmetric(horizontal: screenEdge);
  static const EdgeInsets listItem =
      EdgeInsets.symmetric(horizontal: screenEdge, vertical: 12);
  static const EdgeInsets button =
      EdgeInsets.symmetric(horizontal: 32, vertical: 14);
}
