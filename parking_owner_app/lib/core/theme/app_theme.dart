import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static TextTheme _textTheme(Color primary) => TextTheme(
        displayLarge: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.w700, color: primary),
        headlineLarge: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700, color: primary),
        headlineMedium: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: primary),
        bodyLarge: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w400, color: primary),
        bodyMedium: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400, color: primary),
        bodySmall: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700),
        labelSmall: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
      );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        tertiary: AppColors.accentLight,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: _textTheme(AppColors.textLight),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.subtextLight,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accentLight.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryLight.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accentLight, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryDark,
        secondary: AppColors.secondaryLight,
        tertiary: AppColors.accentLight,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _textTheme(AppColors.textDark),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.subtextDark,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDark.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDark.withOpacity(0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDark, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
