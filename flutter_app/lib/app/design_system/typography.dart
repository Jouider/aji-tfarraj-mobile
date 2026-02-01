import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';

/// Aji Tfarraj Typography
/// FR → Inter | AR → Cairo
/// Weights: Regular (400), Medium (500), SemiBold (600)
class AppTypography {
  AppTypography._();

  // ============================================
  // Font Weights
  // ============================================
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;

  // ============================================
  // Font Families
  // ============================================
  
  /// French / Latin font - Inter
  static String get fontFamilyFr => GoogleFonts.inter().fontFamily!;
  
  /// Arabic font - Cairo
  static String get fontFamilyAr => GoogleFonts.cairo().fontFamily!;

  // ============================================
  // Headings (FR - Inter)
  // ============================================
  
  /// H1 - Page titles
  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// H2 - Section titles
  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// H3 - Card titles
  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// H4 - Subtitles
  static TextStyle get h4 => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: medium,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ============================================
  // Body Text (FR - Inter)
  // ============================================
  
  /// Body Large - Main content
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// Body Medium - Default body text
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// Body Small - Captions, hints
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: regular,
        color: AppColors.textMuted,
        height: 1.5,
      );

  // ============================================
  // Labels (FR - Inter)
  // ============================================
  
  /// Label Large - Form labels
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: medium,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Label Medium - Button text
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: medium,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Label Small - Chips, badges
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: medium,
        color: AppColors.textMuted,
        height: 1.4,
      );

  /// Caption - Helper text, timestamps
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: regular,
        color: AppColors.textMuted,
        height: 1.4,
      );

  // ============================================
  // Button Text
  // ============================================
  
  /// Button Large - Primary buttons
  static TextStyle get buttonLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: semiBold,
        color: AppColors.backgroundWhite,
        height: 1.2,
      );

  /// Button Medium - Secondary buttons
  static TextStyle get buttonMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: semiBold,
        color: AppColors.backgroundWhite,
        height: 1.2,
      );

  // ============================================
  // Arabic Typography (Cairo)
  // ============================================
  
  /// Arabic H1
  static TextStyle get h1Ar => GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Arabic H2
  static TextStyle get h2Ar => GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Arabic H3
  static TextStyle get h3Ar => GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// Arabic H4
  static TextStyle get h4Ar => GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: medium,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// Arabic Body Large
  static TextStyle get bodyLargeAr => GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  /// Arabic Body Medium
  static TextStyle get bodyMediumAr => GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  /// Arabic Body Small
  static TextStyle get bodySmallAr => GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: regular,
        color: AppColors.textMuted,
        height: 1.6,
      );

  /// Arabic Button
  static TextStyle get buttonAr => GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: semiBold,
        color: AppColors.backgroundWhite,
        height: 1.3,
      );

  // ============================================
  // Helper Methods
  // ============================================
  
  /// Get text style based on locale
  static TextStyle getLocalizedStyle(TextStyle frStyle, TextStyle arStyle, Locale locale) {
    return locale.languageCode == 'ar' ? arStyle : frStyle;
  }
}
