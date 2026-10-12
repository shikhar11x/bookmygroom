import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Playfair Display for editorial headlines, Inter for the interface.
class AppTypography {
  AppTypography._();

  static TextStyle display(Color color) => GoogleFonts.playfairDisplay(
    fontSize: 40,
    height: 1.1,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
    color: color,
  );

  static TextStyle headline(Color color) => GoogleFonts.playfairDisplay(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextStyle title(Color color) => GoogleFonts.playfairDisplay(
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: display(primary),
      displayMedium: headline(primary),
      headlineLarge: headline(primary),
      headlineMedium: headline(primary),
      headlineSmall: title(primary),
      titleLarge: title(primary),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.5, color: primary),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.5,
        color: secondary,
      ),
      bodySmall: GoogleFonts.inter(fontSize: 12, height: 1.4, color: secondary),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: primary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: secondary,
      ),
    );
  }
}
