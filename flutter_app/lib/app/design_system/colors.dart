import 'package:flutter/material.dart';

/// Aji Tfarraj Color Palette
/// Official colors based on brand identity
class AppColors {
  AppColors._();

  // ============================================
  // Primary Colors
  // ============================================
  
  /// Primary / Bordeaux - Main CTA, buttons, approved badges
  static const Color primary = Color(0xFF8B1E3F);
  static const Color primaryLight = Color(0xFFB84A6B);
  static const Color primaryDark = Color(0xFF5E0A24);

  // ============================================
  // Secondary Colors
  // ============================================
  
  /// Secondary / Orange - Accents, icons, highlights, loading
  static const Color secondary = Color(0xFFF4A21E);
  static const Color secondaryLight = Color(0xFFFFC04D);
  static const Color secondaryDark = Color(0xFFC77B00);

  // ============================================
  // Neutral Colors
  // ============================================
  
  /// Text colors
  static const Color textPrimary = Color(0xFF2E2E2E);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  
  /// Background colors
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGrey = Color(0xFFF7F7F7);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  
  /// Border colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);
  
  /// Disabled state
  static const Color disabled = Color(0xFFD1D5DB);

  // ============================================
  // Status Colors
  // ============================================
  
  /// Success (approved / checked_in)
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF15803D);
  
  /// Warning (pending / contacting)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);
  
  /// Error (rejected / expired)
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFB91C1C);
  
  /// Info (cancelled / neutral)
  static const Color info = Color(0xFF6B7280);
  static const Color infoLight = Color(0xFFF3F4F6);
  static const Color infoDark = Color(0xFF4B5563);

  // ============================================
  // Semantic Helpers
  // ============================================
  
  /// Get status color by status key
  static Color getStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'checked_in':
        return success;
      case 'pending_review':
      case 'contacting':
        return warning;
      case 'rejected':
      case 'expired':
        return error;
      case 'cancelled':
      default:
        return info;
    }
  }
  
  /// Get status background color by status key
  static Color getStatusBackgroundColor(String status) {
    switch (status) {
      case 'approved':
      case 'checked_in':
        return successLight;
      case 'pending_review':
      case 'contacting':
        return warningLight;
      case 'rejected':
      case 'expired':
        return errorLight;
      case 'cancelled':
      default:
        return infoLight;
    }
  }
}
