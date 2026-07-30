/// Design tokens — CLAUDE.md invariant 13. Keep in sync with munshi-ui's
/// CSS custom properties; do not introduce a second visual language here.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MunshiColors {
  static const inkGreen = Color(0xFF0F2E27);
  static const brassGold = Color(0xFFB08D57);
  static const ivory = Color(0xFFF7F5F0);

  /// Right/green bubbles = court-derived; left/white bubbles = the lawyer's
  /// own actions (CLAUDE.md header) — the WhatsApp mental model must hold in
  /// the Flutter chat view exactly as it does in munshi-ui. Brass gold stays
  /// reserved for attention/urgency accents, not bubble color, per invariant 13.
  static const courtBubble = inkGreen;
  static const lawyerBubble = Colors.white;
}

ThemeData munshiTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MunshiColors.inkGreen,
      primary: MunshiColors.inkGreen,
      secondary: MunshiColors.brassGold,
      surface: MunshiColors.ivory,
    ),
    scaffoldBackgroundColor: MunshiColors.ivory,
  );
  // Inter for UI text, Fraunces for wordmark/numerals/avatars (CLAUDE.md
  // invariant 13). google_fonts fetches both once and caches on-device; text
  // renders with the platform fallback until that first fetch completes,
  // then repaints in place — no extra plumbing needed here.
  final interTextTheme = GoogleFonts.interTextTheme(base.textTheme);
  return base.copyWith(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MunshiColors.brassGold, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.grey.shade700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MunshiColors.inkGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MunshiColors.inkGreen,
        side: BorderSide(color: Colors.grey.shade400),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textTheme: interTextTheme.copyWith(
      // Wordmark/numerals/avatars use Fraunces (serif) — see index.html.
      headlineMedium: GoogleFonts.fraunces(
        textStyle: interTextTheme.headlineMedium,
        color: MunshiColors.inkGreen,
      ),
    ),
  );
}
