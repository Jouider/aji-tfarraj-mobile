import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';

/// Aji Tfarraj App Theme
/// Combines all design tokens into a Material Theme
class AppTheme {
  AppTheme._();

  /// Light theme (default)
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        
        // Colors
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundWhite,
        
        // Color Scheme
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.backgroundWhite,
          secondary: AppColors.secondary,
          onSecondary: AppColors.textPrimary,
          error: AppColors.error,
          onError: AppColors.backgroundWhite,
          surface: AppColors.backgroundWhite,
          onSurface: AppColors.textPrimary,
        ),
        
        // AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.backgroundWhite,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.h4,
          iconTheme: const IconThemeData(
            color: AppColors.textPrimary,
            size: AppSpacing.iconLg,
          ),
        ),
        
        // Text Theme
        textTheme: TextTheme(
          displayLarge: AppTypography.h1,
          displayMedium: AppTypography.h2,
          displaySmall: AppTypography.h3,
          headlineMedium: AppTypography.h4,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.bodyMedium,
          bodySmall: AppTypography.bodySmall,
          labelLarge: AppTypography.labelLarge,
          labelMedium: AppTypography.labelMedium,
          labelSmall: AppTypography.labelSmall,
        ),
        
        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        
        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.backgroundWhite,
            elevation: 0,
            minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            textStyle: AppTypography.buttonLarge,
          ),
        ),
        
        // Outlined Button Theme
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            textStyle: AppTypography.buttonLarge.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        
        // Text Button Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTypography.labelLarge,
          ),
        ),
        
        // Card Theme
        cardTheme: CardThemeData(
          color: AppColors.backgroundWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
        ),
        
        // Divider Theme
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
        
        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.backgroundWhite,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        
        // Chip Theme
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.backgroundGrey,
          labelStyle: AppTypography.labelMedium,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
        
        // Progress Indicator Theme
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.secondary,
          linearTrackColor: AppColors.backgroundGrey,
        ),
        
        // Snackbar Theme
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.backgroundWhite,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      );
}
