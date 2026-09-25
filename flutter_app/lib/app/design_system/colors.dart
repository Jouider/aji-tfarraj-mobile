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

  /// Pour les rares endroits qui doivent choisir une valeur hors palette —
  /// une opacité d'ombre, par exemple.
  static bool get isDark => _isDark;

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

  // ============================================
  // Verre
  // ============================================
  //
  // Une règle, et elle tient en une phrase : **sur une photo le verre est
  // sombre, sur la page il prend la couleur du thème**.
  //
  // Une photo n'a pas de thème. Elle est sombre ou claire selon ce qu'elle
  // montre, jamais selon le réglage du téléphone, et l'encre blanche qu'on
  // écrit dessus a besoin d'un voile sombre dans les deux cas. La page, elle,
  // suit le thème : un voile noir posé sur une page blanche donne la plaque
  // grise sale qu'on voyait en thème clair.

  /// Le verre posé sur la page : barre d'onglets, capsules flottantes.
  ///
  /// L'opacité n'est pas un réglage de goût, c'est ce qui borne le fond. Un
  /// voile d'alpha `a` posé sur n'importe quoi donne un fond compris entre
  /// `a × voile` et `a × voile + (1-a) × 255` — et c'est le pire bout de cet
  /// intervalle qui décide si le libellé se lit.
  ///
  /// À 34 %, l'ancien voile sombre laissait le fond monter jusqu'à 168 sur une
  /// affiche claire : le gris des onglets inactifs y tombait à **1,6:1**, ce
  /// qui veut dire invisible. À 62 % le fond plafonne à 97, et le même gris
  /// remonte à 4,2:1. Côté clair, 82 % plancher le fond à 209 et l'encre
  /// sombre tient 4,9:1.
  static Color get glassSurface => _isDark
      ? const Color(0x9E000000) // noir 62 %
      : const Color(0xD1FFFFFF); // blanc 82 %

  /// Son liseré — assez pour dessiner le bord, jamais assez pour se voir.
  static Color get glassBorder => _isDark
      ? const Color(0x1FFFFFFF) // blanc 12 %
      : const Color(0x14000000); // noir 8 %

  /// La capsule de l'onglet actif — **opaque**, et c'est tout l'intérêt.
  ///
  /// Tant qu'elle était translucide, la couleur de l'onglet actif dépendait de
  /// l'affiche qui défilait derrière : l'or de la charte tombait à 2,3:1 dès
  /// qu'une image claire passait sous la barre. Opaque, elle devient sa propre
  /// surface — l'or y tient 7,8:1 quoi qu'il y ait derrière.
  static Color get glassHighlight =>
      _isDark ? const Color(0xFF24242A) : const Color(0xFFFDE8DD);

  /// L'encre de l'onglet actif, sur cette capsule. L'or de la charte brille
  /// sur du sombre et s'efface sur du clair : en thème clair, c'est le rouge
  /// orangé de la charte qui prend le relais — 5,0:1 sur la capsule pâle.
  static Color get glassAccent => _isDark ? secondary : primaryDark;

  /// Le verre posé sur une photo : sombre dans les deux thèmes.
  static const Color glassOnPhoto = Color(0x57000000); // noir 34 %

  /// Sa variante sans flou, pour une étiquette lue en vitesse dans une liste.
  ///
  /// Plus dense que [glassOnPhoto], et pour une raison mesurée : sans flou, le
  /// voile est tout ce qui sépare l'encre blanche de l'affiche. À 42 %, une
  /// affiche claire remontait le fond à 148 et le blanc n'y tenait que
  /// 3,0:1 — la pastille « MEDI1 » sur la carte rose. À 62 %, le fond
  /// plafonne à 97 et le blanc tient 6,2:1 quelle que soit l'affiche.
  static const Color glassOnPhotoSolid = Color(0x9E000000); // noir 62 %

  static const Color glassOnPhotoBorder = Color(0x29FFFFFF); // blanc 16 %

  /// L'encre écrite sur une affiche. Blanche, dans les deux thèmes.
  ///
  /// Le corollaire de [glassOnPhoto] : un jeton de texte qui suit le thème
  /// (`textPrimary`, `textSecondary`…) n'a rien à faire sur une photo. En
  /// thème clair il devient sombre, et il disparaît dans le voile.
  static const Color inkOnPhoto = Color(0xFFFFFFFF);

  /// Sa variante secondaire — une date, un lieu, un décompte.
  static const Color inkOnPhotoMuted = Color(0xE0FFFFFF); // blanc 88 %

  // ============================================
  // Puces de filtre
  // ============================================

  /// Une puce de filtre choisie.
  ///
  /// L'or plein qu'elle portait avant était l'élément le plus lumineux de
  /// l'écran (0,47 de luminance sur une page à 0,01) — pour dire « aucun
  /// filtre », l'état par défaut. Avec un halo doré autour, en plus. Le rouge
  /// orangé de la charte descend à 0,13 : trois fois et demie moins lumineux,
  /// toujours la marque, et il ne se confond pas avec l'or des places.
  static Color get chipSelected => primaryAction;

  /// Son encre — 4,6:1, mesuré.
  static const Color chipSelectedInk = onPrimary;

  // ============================================
  // L'or, en aplat et en encre
  // ============================================

  /// L'or de la charte **écrit** : un libellé, une icône, un lien.
  ///
  /// [secondary] est un APLAT. Il est fait pour qu'on pose de l'encre sombre
  /// dessus, et il ne bouge pas avec le thème — c'est même garanti par un
  /// test. Mais l'or n'est pas une encre : sur la page claire il tombe à
  /// **1,89:1**, ce qui veut dire illisible. « Voir tout » était dans ce
  /// cas, et 70 autres libellés et icônes avec lui.
  ///
  /// Sur la page sombre, l'or reste l'or : 10,1:1. Sur la page claire, c'est
  /// le rouge orangé de la charte qui prend le relais : 5,6:1. Même famille,
  /// même intention, lisible des deux côtés.
  ///
  /// Ne s'applique PAS à l'encre posée sur une affiche : là c'est
  /// [inkOnPhoto] qui décide, parce qu'une affiche n'a pas de thème.
  static Color get accentInk => _isDark ? secondary : primaryDark;

  /// L'exception, et la seule : l'or écrit SUR une affiche.
  ///
  /// Là, il ne bouge pas. Le voile derrière est sombre dans les deux thèmes —
  /// une affiche n'a pas de thème —, donc l'or y tient 10:1 en clair comme en
  /// sombre, tandis que le rouge orangé d'[accentInk] s'y noierait.
  static const Color accentInkOnPhoto = secondary;

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
