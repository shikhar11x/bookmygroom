import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: AppColors.ivory,
      secondary: AppColors.champagne,
      onSecondary: AppColors.ink,
      surface: AppColors.ivory,
      onSurface: AppColors.ink,
      error: AppColors.error,
      outline: AppColors.beige,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ivory,
      textTheme: AppTypography.textTheme(AppColors.ink, AppColors.taupe),
      splashFactory: InkRipple.splashFactory,
      dividerTheme: const DividerThemeData(
        color: AppColors.beige,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title(AppColors.ink),
        foregroundColor: AppColors.ink,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.ivory,
        indicatorColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? AppColors.ink : AppColors.taupeLight,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.ink : AppColors.taupeLight,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.taupe),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.champagne, width: 1.2),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.ivory,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
    );
  }
}
