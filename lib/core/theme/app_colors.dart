import 'package:flutter/material.dart';

/// ============================================================================
/// MATCH SPACE — "Terracotta & Slate" palette
/// ----------------------------------------------------------------------------
/// Earth-clay warmth (Nigerian laterite soil, hand-formed architecture) set
/// against deep slate, with a crisp emerald reserved for trust / availability
/// signals. Terracotta is used as a STRUCTURAL accent, never as a full-page
/// wash, to stay clear of the generic cream-serif-terracotta look.
/// ============================================================================
class AppColors {
  AppColors._();

  // Brand
  static const Color terracotta = Color(0xFFC75B39); // primary clay
  static const Color terracottaDark = Color(0xFF9E4226);
  static const Color terracottaSoft = Color(0xFFF3D9CE); // tints, chips
  static const Color ochre = Color(0xFFE0A458); // warm secondary

  // Slate (surfaces & text)
  static const Color slate900 = Color(0xFF15181C); // near-black bg
  static const Color slate800 = Color(0xFF1E232A);
  static const Color slate700 = Color(0xFF2A313A);
  static const Color slate500 = Color(0xFF5B6470);
  static const Color slate400 = Color(0xFF8A94A3);
  static const Color slate200 = Color(0xFFD9DEE5);
  static const Color slate100 = Color(0xFFEDF0F3);

  // Trust / status
  static const Color emerald = Color(0xFF2FA66E); // available, verified
  static const Color amber = Color(0xFFE0A458); // pending
  static const Color ruby = Color(0xFFD64550); // error / rejected

  // Surfaces (light theme is primary for the listing experience)
  static const Color canvas = Color(0xFFFBF9F6); // warm off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF4F0EB);
  static const Color border = Color(0xFFE7E1D8);

  // Text
  static const Color ink = Color(0xFF1B1E22);
  static const Color inkSoft = Color(0xFF5A6068);
  static const Color inkFaint = Color(0xFF9AA0A8);

  static const Color onTerracotta = Color(0xFFFFFFFF);
}
