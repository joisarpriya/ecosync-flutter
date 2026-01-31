import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConfig {
  // Spacing scale
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;

  // Border radius (Material 3 friendly)
  static const double radius = 18.0;
  static const double cardRadius = 20.0;

  // Brand colors (Google-style tokens)
  static const Color seedBlue = Color(0xFF1A73E8);
  static const Color goodGreen = Color(0xFF34A853);
  static const Color cautionYellow = Color(0xFFFBBC04);
  static const Color dangerRed = Color(0xFFEA4335);


  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(seedColor: seedBlue, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Google background
      cardColor: Colors.white,
      shadowColor: Colors.black.withOpacity(0.04),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),

      // Use Inter via google_fonts for a Material-like system font with good legibility.
      textTheme: GoogleFonts.interTextTheme(Typography.blackMountainView).copyWith(
        bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400),
        headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w400, color: Colors.black54),
      ),
    );
  }


}
