import 'package:flutter/material.dart';

/// Aji Tfarraj Color Palette
/// Dark premium theme inspired by cinematic app design
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

  /// Secondary / Gold - Accents, icons, highlights, selected states
  static const Color secondary = Color(0xFFF4A21E);
  static const Color secondaryLight = Color(0xFFFFC04D);
  static const Color secondaryDark = Color(0xFFC77B00);

  // ============================================
  // Neutral / Dark Theme Surfaces
  // ============================================

  /// Text colors (on dark backgrounds)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFD1D5DB);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textLight = Color(0xFF6B7280);

  /// Background / Surface colors — dark theme
  static const Color backgroundWhite = Color(0xFF0C0C0C);   // Main scaffold background
  static const Color backgroundGrey = Color(0xFF1C1C1E);    // Card / chip backgrounds
  static const Color backgroundLight = Color(0xFF111111);   // Slightly elevated surfaces

  /// Elevated card surface (hero card, modals)
  static const Color cardDarkElevated = Color(0xFF252528);

  /// Surface overlay (bottom sheets, dialogs)
  static const Color surfaceOverlay = Color(0xFF1A1A1C);

  /// Border colors
  static const Color border = Color(0xFF2C2C2E);
  static const Color borderLight = Color(0xFF3A3A3C);
  static const Color divider = Color(0xFF2C2C2E);

  /// Disabled state
  static const Color disabled = Color(0xFF3A3A3C);

  // ============================================
  // Status Colors
  // ============================================

  /// Success (approved / checked_in)
  static const Color success = Color(0xFF4ADE80);
  static const Color successLight = Color(0xFF0D3320);
  static const Color successDark = Color(0xFF16A34A);

  /// Warning (pending / contacting)
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFF3D2400);
  static const Color warningDark = Color(0xFFD97706);

  /// Error (rejected / expired)
  static const Color error = Color(0xFFF87171);
  static const Color errorLight = Color(0xFF3D0A0A);
  static const Color errorDark = Color(0xFFDC2626);

  /// Info (cancelled / neutral)
  static const Color info = Color(0xFF9CA3AF);
  static const Color infoLight = Color(0xFF252528);
  static const Color infoDark = Color(0xFF6B7280);

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
