// file: lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.system,
  );

  static const String _themeKey = "theme_mode";

  // Load theme from storage on app start
  static Future<void> initTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme == "dark") {
      themeNotifier.value = ThemeMode.dark;
    } else if (savedTheme == "light") {
      themeNotifier.value = ThemeMode.light;
    } else {
      themeNotifier.value = ThemeMode.system;
    }
  }

  // Save theme when user toggles it
  static Future<void> saveTheme(ThemeMode mode) async {
    themeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setString(_themeKey, "dark");
    } else {
      await prefs.setString(_themeKey, "light");
    }
  }

  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color darkRed = Color(0xFF8E0000);
  static const Color accentPink = Color(0xFFFFCDD2);
  static const Color surfaceWhite = Color(0xFFFAFAFA);

  // Dark Mode specific colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);

  // New Color for Legends
  static const Color gold = Color(0xFFFFD700);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: surfaceWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        secondary: darkRed,
        surface: surfaceWhite,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 4,
        surfaceTintColor: Colors.white,
      ),
      // Dialogs & Pickers
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

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        brightness: Brightness.dark,
        primary: primaryRed,
        surface: darkSurface,
        onSurface: Colors.white,
        background: darkBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryRed,
        unselectedItemColor: Colors.grey,
        backgroundColor: darkSurface,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintStyle: TextStyle(color: Colors.grey[400]),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
        elevation: 4,
        surfaceTintColor: darkCard, // Removes standard M3 purple tint
      ),
      // Fix Dialogs in Dark Mode
      dialogTheme: const DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: darkCard,
        titleTextStyle: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        contentTextStyle: TextStyle(fontSize: 16, color: Colors.white70),
      ),
      // Fix Date Picker in Dark Mode
      datePickerTheme: DatePickerThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: darkCard,
        headerBackgroundColor: darkSurface,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.all(Colors.white),
        yearForegroundColor: WidgetStateProperty.all(Colors.white),
        todayBackgroundColor: WidgetStateProperty.all(primaryRed),
        todayForegroundColor: WidgetStateProperty.all(Colors.white),
      ),
      // Fix Bottom Sheet in Dark Mode
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: darkSurface,
        modalBackgroundColor: darkSurface,
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
    );
  }
}
