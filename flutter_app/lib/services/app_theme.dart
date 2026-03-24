import 'package:flutter/material.dart';

class AppTheme {
  // Color palette
  static const Color primary = Color(0xFF6C63FF);       // Vibrant purple
  static const Color primaryDark = Color(0xFF4A3FE3);
  static const Color accent = Color(0xFFFF6584);         // Coral pink accent
  static const Color surface = Color(0xFF1E1E2E);        // Dark surface
  static const Color surfaceCard = Color(0xFF2A2A3E);    // Card background
  static const Color surfaceCardLight = Color(0xFF313149);
  static const Color onSurface = Color(0xFFE2E2F0);      // Text on dark
  static const Color onSurfaceMuted = Color(0xFF9191B0); // Muted text
  static const Color success = Color(0xFF43E97B);        // Green for Done
  static const Color warning = Color(0xFFFFAD60);        // Orange for In Progress
  static const Color blocked = Color(0xFF5C5C7A);        // Grey for blocked

  // Status colors
  static Color statusColor(String status) {
    switch (status) {
      case 'Done':
        return success;
      case 'In Progress':
        return warning;
      case 'To-Do':
      default:
        return primary;
    }
  }

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurface,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: onSurfaceMuted),
        hintStyle: const TextStyle(color: onSurfaceMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceCardLight,
        selectedColor: primary,
        labelStyle: const TextStyle(color: onSurface, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}