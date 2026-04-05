import 'package:flutter/material.dart';

/// Aji Tfarraj Color Palette
/// Supports both dark and light themes via dynamic brightness resolution
class AppColors {
  AppColors._();

  // ============================================
  // Brightness State
  // ============================================

  static Brightness _brightness = Brightness.dark;

  /// Update the current brightness (called from the root widget)
  static void updateBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get _isDark => _brightness == Brightness.dark;

  // ============================================
  // Primary Colors (same in both modes)
  // ============================================

  /// Primary / Bordeaux - Main CTA, buttons, approved badges
  static const Color primary = Color(0xFF8B1E3F);
  static const Color primaryLight = Color(0xFFB84A6B);
  static const Color primaryDark = Color(0xFF5E0A24);

  // ============================================
  // Secondary Colors (same in both modes)
  // ============================================

  /// Secondary / Gold - Accents, icons, highlights, selected states
  static const Color secondary = Color(0xFFF4A21E);
  static const Color secondaryLight = Color(0xFFFFC04D);
  static const Color secondaryDark = Color(0xFFC77B00);

  // ============================================
  // Text Colors
  // ============================================

  static Color get textPrimary =>
      _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);

  static Color get textSecondary =>
      _isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563);

  static Color get textMuted =>
      _isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  static Color get textLight =>
      _isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

  // ============================================
  // Background / Surface Colors
  // ============================================

  /// Main scaffold background
  static Color get backgroundWhite =>
      _isDark ? const Color(0xFF0C0C0C) : const Color(0xFFFAFAFA);

  /// Card / chip backgrounds
  static Color get backgroundGrey =>
      _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF3F4F6);

  /// Slightly elevated surfaces
  static Color get backgroundLight =>
      _isDark ? const Color(0xFF111111) : const Color(0xFFFFFFFF);

  /// Elevated card surface (hero card, modals)
  static Color get cardDarkElevated =>
      _isDark ? const Color(0xFF252528) : const Color(0xFFFFFFFF);

  /// Surface overlay (bottom sheets, dialogs)
  static Color get surfaceOverlay =>
      _isDark ? const Color(0xFF1A1A1C) : const Color(0xFFFFFFFF);

  // ============================================
  // Border Colors
  // ============================================

  static Color get border =>
      _isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB);

  static Color get borderLight =>
      _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D5DB);

  static Color get divider =>
      _isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E7EB);

  /// Disabled state
  static Color get disabled =>
      _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D5DB);

  // ============================================
  // Status Colors (foreground — same in both modes)
  // ============================================

  /// Success (approved / checked_in)
  static const Color success = Color(0xFF4ADE80);
  static const Color successDark = Color(0xFF16A34A);

  /// Warning (pending / contacting)
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);

  /// Error (rejected / expired)
  static const Color error = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);

  /// Info (cancelled / neutral)
  static const Color info = Color(0xFF9CA3AF);
  static const Color infoDark = Color(0xFF6B7280);

  // ============================================
  // Status Background Colors (theme-aware)
  // ============================================

  static Color get successLight =>
      _isDark ? const Color(0xFF0D3320) : const Color(0xFFDCFCE7);

  static Color get warningLight =>
      _isDark ? const Color(0xFF3D2400) : const Color(0xFFFEF3C7);

  static Color get errorLight =>
      _isDark ? const Color(0xFF3D0A0A) : const Color(0xFFFEE2E2);

  static Color get infoLight =>
      _isDark ? const Color(0xFF252528) : const Color(0xFFF3F4F6);

  // ============================================
  // Button Text (always white, for primary-colored buttons)
  // ============================================

  static const Color buttonText = Colors.white;

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

  /// Get theme-aware foreground (text/icon) color for status badges
  /// Darkened variants in light mode for readability, bright in dark mode
  // FIX: Status badge foreground colors — readable on both themes
  static Color getStatusForegroundColor(String status) {
    switch (status) {
      case 'approved':
      case 'checked_in':
        return _isDark ? success : successDark; // #4ADE80 / #16A34A
      case 'pending_review':
      case 'contacting':
        return _isDark ? secondaryLight : secondaryDark; // #FFC04D / #C77B00
      case 'rejected':
      case 'expired':
        return _isDark ? error : errorDark; // #F87171 / #DC2626
      case 'cancelled':
      default:
        return textMuted;
    }
  }

  /// Get border color for status badges (status-tinted, alpha-reduced)
  // FIX: Status badge border colors — tinted by status family
  static Color getStatusBorderColor(String status) {
    switch (status) {
      case 'pending_review':
      case 'contacting':
        return secondary.withValues(alpha: 0.40);
      case 'approved':
      case 'checked_in':
        return (_isDark ? success : successDark).withValues(alpha: 0.30);
      case 'rejected':
      case 'expired':
        return (_isDark ? error : errorDark).withValues(alpha: 0.30);
      case 'cancelled':
      default:
        return textMuted.withValues(alpha: 0.25);
    }
  }
}
