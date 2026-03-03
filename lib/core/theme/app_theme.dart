// file: lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  static const String _themeKey = "theme_mode";

  static Future<void> initTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    if (saved == "dark") {
      themeNotifier.value = ThemeMode.dark;
    } else if (saved == "light") {
      themeNotifier.value = ThemeMode.light;
    } else {
      themeNotifier.value = ThemeMode.system;
    }
  }

  static Future<void> saveTheme(ThemeMode mode) async {
    themeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.dark ? "dark" : "light");
  }

  // ── Brand ──────────────────────────────────────────────────────
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color darkRed = Color(0xFF8E0000);
  static const Color accentPink = Color(0xFFFFCDD2);
  static const Color surfaceWhite = Color(0xFFFAFAFA);
  static const Color gold = Color(0xFFFFD700);

  // ── Dark palette — warm-tinted so red always pops ─────────────
  //
  //  Think of it as charcoal with a faint red-brown undertone,
  //  creating three distinct elevation levels that stay readable.
  //
  static const Color darkBackground = Color(0xFF100D0D); // near-black, warm
  static const Color darkSurface = Color(0xFF1C1717); // cards / nav bar
  static const Color darkCard = Color(0xFF252020); // elevated cards
  static const Color darkDivider = Color(0xFF332A2A); // subtle separator
  static const Color darkHint = Color(0xFF7A6F6F); // placeholder text
  static const Color darkIcon = Color(0xFFB0A4A4); // secondary icons

  // ── Light theme ───────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        secondary: darkRed,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryRed,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 4,
        surfaceTintColor: Colors.white,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        headerBackgroundColor: primaryRed,
        headerForegroundColor: Colors.white,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
    );
  }

  // ── Dark theme ────────────────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,

      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        // Brand
        primary: primaryRed,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFF4A1010),
        onPrimaryContainer: const Color(0xFFFFDAD6),
        // Secondary
        secondary: const Color(0xFFE57373),
        onSecondary: const Color(0xFF4A1010),
        secondaryContainer: const Color(0xFF3A1515),
        onSecondaryContainer: const Color(0xFFFFB4AB),
        // Surface levels — warm-tinted
        surface: darkSurface,
        onSurface: const Color(0xFFEDE0E0),
        surfaceContainerHighest: darkCard,
        // Error
        error: const Color(0xFFFF6B6B),
        onError: Colors.black,
        // Background
        background: darkBackground,
        onBackground: const Color(0xFFEDE0E0),
        // Outline
        outline: darkDivider,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Color(0xFFEDE0E0),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: Color(0xFFEF9A9A),
        unselectedItemColor: Color(0xFF7A6F6F),
        backgroundColor: darkSurface,
        elevation: 8,
      ),

      // Cards get the elevated warm surface
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      // Text fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F1A1A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkDivider, width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkDivider, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryRed, width: 1.5)),
        hintStyle: const TextStyle(color: darkHint),
        labelStyle: const TextStyle(color: Color(0xFFB0A4A4)),
        prefixIconColor: darkIcon,
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
      ),

      // Dialogs
      dialogTheme: const DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        titleTextStyle:
            TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFEDE0E0)),
        contentTextStyle: TextStyle(fontSize: 15, color: Color(0xFFB0A4A4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
      ),

      // Date picker
      datePickerTheme: DatePickerThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: const Color(0xFF1C1717),
        headerForegroundColor: const Color(0xFFEDE0E0),
        dayForegroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : const Color(0xFFEDE0E0)),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primaryRed : Colors.transparent),
        yearForegroundColor: WidgetStateProperty.all(const Color(0xFFEDE0E0)),
        todayBackgroundColor: WidgetStateProperty.all(primaryRed.withOpacity(0.2)),
        todayForegroundColor: WidgetStateProperty.all(const Color(0xFFEF9A9A)),
        todayBorder: const BorderSide(color: primaryRed, width: 1),
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Switches
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primaryRed : const Color(0xFF5A4F4F)),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
            ? primaryRed.withOpacity(0.35)
            : const Color(0xFF332A2A)),
      ),

      // Icons
      iconTheme: const IconThemeData(color: Color(0xFFB0A4A4)),
      primaryIconTheme: const IconThemeData(color: Color(0xFFEDE0E0)),

      // Popups / dropdowns
      popupMenuTheme: const PopupMenuThemeData(
        color: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),

      // Snack bars
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2F2828),
        contentTextStyle: TextStyle(color: Color(0xFFEDE0E0), fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
