import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralised ThemeData. Display face: Fraunces (characterful serif, used with
/// restraint for headings). Body face: Plus Jakarta Sans. Utility/data: same
/// body family at tighter tracking.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.fraunces(
        fontSize: 52, fontWeight: FontWeight.w600, height: 1.05,
        letterSpacing: -1.0, color: AppColors.ink,
      ),
      displaySmall: GoogleFonts.fraunces(
        fontSize: 34, fontWeight: FontWeight.w600, height: 1.1,
        letterSpacing: -0.5, color: AppColors.ink,
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.ink,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15.5, height: 1.55, color: AppColors.ink,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14, height: 1.5, color: AppColors.inkSoft,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: AppColors.terracotta,
        onPrimary: AppColors.onTerracotta,
        secondary: AppColors.ochre,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.ruby,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.ink),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: AppColors.onTerracotta,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 1.6),
        ),
        hintStyle: const TextStyle(color: AppColors.inkFaint),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceAlt,
        side: const BorderSide(color: AppColors.border),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}
