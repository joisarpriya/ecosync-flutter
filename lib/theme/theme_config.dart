import 'package:flutter/material.dart';

class ThemeConfig {
  // Spacing scale
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;

  // Border radius
  static const double radius = 14.0;

  // Primary gradient used across the app
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32));
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF3F6F4), // soft off-white
      cardColor: Colors.white.withOpacity(0.92),
      shadowColor: Colors.black.withOpacity(0.06),
      // Card appearance adjusted via GlassCard and explicit Card usage where needed
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(elevation: 6),
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF66BB6A), brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F1412),
      cardColor: Colors.white.withOpacity(0.04),
      shadowColor: Colors.black.withOpacity(0.06),
      // Card appearance adjusted via GlassCard and explicit Card usage where needed
    );
  }
}
