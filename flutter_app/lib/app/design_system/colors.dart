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

  /// Orange de marque — l'action : boutons principaux, badges approuvés.
  ///
  /// Charte « logo AJI TFARRAJ », septembre 2026. [primary] est le départ du
  /// dégradé chaud, [primaryDark] son arrivée ; un aplat uni utilise
  /// [primary], une surface qui respire utilise [hotGradient].
  static const Color primary = Color(0xFFF15C24);
  static const Color primaryLight = Color(0xFFF5813F);
  static const Color primaryDark = Color(0xFFB73626);

  /// L'encre posée SUR l'orange : blanche, comme le logo sur fond orange.
  ///
  /// Le dégradé de la charte ne supporte AUCUNE encre sur toute sa longueur :
  /// le blanc mesure 3,1:1 sur l'orange clair, l'encre noire 3,3:1 sur le
  /// rouge foncé. Les deux passent sous le seuil de 4,5:1, chacune à un bout.
  ///
  /// D'où deux dégradés distincts : [hotGradient], celui de la charte, pour
  /// les grandes surfaces sans petit texte ; [actionGradient], resserré dans
  /// la moitié SOMBRE, pour tout ce qui porte un libellé — c'est là que le
  /// blanc tient.
  static const Color onPrimary = Color(0xFFF7F8F8);

  /// Le dégradé de la charte, tel quel. Bandeaux, écran de démarrage, vignettes
  /// — jamais de texte fin par-dessus.
  static const LinearGradient hotGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Le dégradé des boutons : la moitié sombre de celui de la charte, là où
  /// le blanc se lit. 4,6:1 au départ, 5,5:1 à l'arrivée.
  ///
  /// L'orange vif de [primary] reste celui des badges et des accents, où rien
  /// n'est écrit par-dessus.
  /// L'orange des surfaces qui portent un libellé : aplats de boutons comme
  /// départ du dégradé. Le blanc y tient (4,6:1), là où il lâche sur
  /// l'orange vif (3,1:1).
  static const Color primaryAction = Color(0xFFC8431A);

  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryAction, primaryDark],
  );

  /// Le dégradé clair : ce qui récompense — points, badges, cadeaux.
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary],
  );

  // ============================================
  // Secondary Colors (same in both modes)
  // ============================================

  /// Orange clair — l'accent : icônes, sélection, points gagnés.
  /// Presque le doré d'avant : la transition passera inaperçue.
  static const Color secondary = Color(0xFFF9A81C);

  /// Ink drawn ON TOP of [secondary].
  ///
  /// Deliberately the same in both themes, because [secondary] is: the gold
  /// does not change, so the ink that stays readable on it does not change
  /// either. White on this gold measures **2.1:1** — below the 3:1 WCAG floor
  /// even for large text — so it is never an option, in either theme.
  ///
  /// Use this rather than a background token that happens to be dark right
  /// now: `backgroundWhite` reads correctly on gold in the dark theme and
  /// becomes unreadable in the light one.
  static const Color onSecondary = Color(0xFF0C0C0C);
  static const Color secondaryLight = Color(0xFFF57E21);
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

  /// Fond principal. Le noir de la charte, très légèrement relevé : du noir
  /// pur sous une carte noire n'a plus de contour sur un écran OLED.
  static Color get backgroundWhite =>
      _isDark ? const Color(0xFF08080A) : const Color(0xFFFAFAFA);

  /// Card / chip backgrounds
  static Color get backgroundGrey =>
      _isDark ? const Color(0xFF1C1C21) : const Color(0xFFF3F4F6);

  /// Slightly elevated surfaces
  static Color get backgroundLight =>
      _isDark ? const Color(0xFF131316) : const Color(0xFFFFFFFF);

  /// Elevated card surface (hero card, modals)
  static Color get cardDarkElevated =>
      _isDark ? const Color(0xFF24242A) : const Color(0xFFFFFFFF);

  /// Surface overlay (bottom sheets, dialogs)
  static Color get surfaceOverlay =>
      _isDark ? const Color(0xFF17171C) : const Color(0xFFFFFFFF);

  // ============================================
  // Border Colors
  // ============================================

  static Color get border =>
      _isDark ? const Color(0xFF2C2C33) : const Color(0xFFE5E7EB);

  static Color get borderLight =>
      _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D5DB);

  static Color get divider =>
      _isDark ? const Color(0xFF2C2C33) : const Color(0xFFE5E7EB);

  /// Disabled state
  static Color get disabled =>
      _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D5DB);

  // ============================================
  // Status Colors (foreground — same in both modes)
  // ============================================

  // Le violet du casting est parti avec le bordeaux : la charte tient à une
  // seule couleur, et une carte violette au milieu de l'orange ressortait
  // comme une erreur. L'espace casting prend le dégradé de marque, le mode
  // chargé public garde le doré — deux mondes distincts, même famille.

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
