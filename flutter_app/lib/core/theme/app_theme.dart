import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Core
  static const Color background = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF131720);
  static const Color surfaceElevated = Color(0xFF1A1F2B);
  static const Color card = Color(0xFF161B26);
  static const Color cardBorder = Color(0xFF1E2433);
  static const Color divider = Color(0xFF1E2433);

  // Primary
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryGlow = Color(0x333B82F6);

  // Risk
  static const Color highRisk = Color(0xFFEF4444);
  static const Color highRiskBg = Color(0x1AEF4444);
  static const Color mediumRisk = Color(0xFFF59E0B);
  static const Color mediumRiskBg = Color(0x1AF59E0B);
  static const Color lowRisk = Color(0xFF22C55E);
  static const Color lowRiskBg = Color(0x1A22C55E);

  // Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF475569);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Accent
  static const Color scanLine = Color(0x663B82F6);
  static const Color overlay = Color(0x80000000);
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.primaryLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 1.2,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }

  static TextStyle headingLarge = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle headingMedium = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle headingSmall = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle subtitleLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle subtitleMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle monospace = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle monospaceLarge = GoogleFonts.jetBrainsMono(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -2,
  );
}
