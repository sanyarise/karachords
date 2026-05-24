import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color primary = Color(0xFFBB86FC);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFCF6679);
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFF000000);
  static const Color onSecondary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textDisabled = Color(0xFF666666);
  static const Color divider = Color(0xFF3A3A3A);
  static const Color primaryContainer = Color(0xFF4A3868);

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        surface: surface,
        primary: primary,
        secondary: secondary,
        error: error,
        onSurface: onSurface,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: onBackground,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      textTheme: GoogleFonts.robotoTextTheme(base.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: onPrimary,
          backgroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: onSurface,
      ),
    );
  }
}
