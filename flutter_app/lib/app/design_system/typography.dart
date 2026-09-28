import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';

/// La typographie d'Aji Tfarraj : deux voix, aucune requête réseau.
///
/// **Les titres parlent Cairo**, la police de la charte, embarquée dans l'app.
/// C'est la même famille en français et en arabe : un titre se ressemble d'une
/// langue à l'autre, ce qu'aucune paire de polices ne sait faire.
///
/// **Tout le reste parle la police du système** — SF Pro sur iPhone, Roboto sur
/// Android. Ce n'est pas un renoncement : à 11–14 px c'est ce qui se lit le
/// mieux, ça suit les réglages d'accessibilité du téléphone, ça couvre l'arabe
/// et le français sans changer de fichier, et ça ne coûte pas un octet. C'est
/// le choix de WhatsApp, d'Instagram et d'Uber.
///
/// Ce que ça remplace : l'app téléchargeait Inter et Cairo chez Google au
/// premier affichage (~900 Ko pour les trois coupes d'Inter). Sur un réseau
/// lent, elle démarrait dans la police du système puis changeait de police
/// sous les yeux du membre ; hors ligne, elle n'avait jamais la bonne. Une
/// police de marque qui dépend du réseau n'est pas une police de marque.
///
/// Règle d'usage : ne jamais écrire `fontFamily` ailleurs que dans ce fichier.
/// Un style sans famille prend celle du système, et c'est voulu.
class AppTypography {
  AppTypography._();

  // ============================================
  // Font Weights
  // ============================================
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  /// Le poids des titres de la charte : Cairo ExtraBold.
  static const FontWeight extraBold = FontWeight.w800;

  // ============================================
  // Font Families
  // ============================================

  /// La police des titres, déclarée dans `pubspec.yaml` en quatre coupes
  /// (400 / 600 / 700 / 800). Demander une graisse absente ne casse rien :
  /// Flutter prend la plus proche — mais le rendu n'est plus celui prévu, donc
  /// on s'en tient à ces quatre.
  static const String fontFamilyTitle = 'Cairo';

  /// La police de l'interface : celle du téléphone. `null` n'est pas un oubli,
  /// c'est la façon dont on la demande à Flutter.
  static const String? fontFamilyUi = null;

  // ============================================
  // Titres — Cairo, embarqué
  // ============================================

  /// H1 — titres de page.
  ///
  /// Cairo est plus large que la police du système : à taille égale un titre
  /// déborde, d'où les deux points de moins. Il s'arrête aux grands titres —
  /// en dessous de 20 px, la police du système reste plus lisible, et c'est là
  /// que vivent les libellés.
  static TextStyle get h1 => TextStyle(
        fontFamily: fontFamilyTitle,
        fontSize: 26,
        fontWeight: extraBold,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// H2 — titres de section.
  static TextStyle get h2 => TextStyle(
        fontFamily: fontFamilyTitle,
        fontSize: 22,
        fontWeight: extraBold,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  /// H3 — titres de carte : la dernière taille où Cairo tient.
  static TextStyle get h3 => TextStyle(
        fontFamily: fontFamilyTitle,
        fontSize: 19,
        fontWeight: bold,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ============================================
  // Interface — police du système
  // ============================================

  /// H4 — sous-titres. Sous la barre des 20 px : on repasse au système.
  static TextStyle get h4 => TextStyle(
        fontSize: 18,
        fontWeight: medium,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Body Large - Main content
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// Body Medium - Default body text
  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// Body Small - Captions, hints
  static TextStyle get bodySmall => TextStyle(
        fontSize: 12,
        fontWeight: regular,
        color: AppColors.textMuted,
        height: 1.5,
      );

  /// Label Large - Form labels
  static TextStyle get labelLarge => TextStyle(
        fontSize: 14,
        fontWeight: medium,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Label Medium - Button text
  static TextStyle get labelMedium => TextStyle(
        fontSize: 14,
        fontWeight: medium,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Label Small - Chips, badges
  static TextStyle get labelSmall => TextStyle(
        fontSize: 12,
        fontWeight: medium,
        color: AppColors.textMuted,
        height: 1.4,
      );

  /// Caption - Helper text, timestamps
  static TextStyle get caption => TextStyle(
        fontSize: 12,
        fontWeight: regular,
        color: AppColors.textMuted,
        height: 1.4,
      );

  /// Button Large - Primary buttons
  static TextStyle get buttonLarge => const TextStyle(
        fontSize: 16,
        fontWeight: semiBold,
        color: AppColors.buttonText,
        height: 1.2,
      );

  /// Button Medium - Secondary buttons
  static TextStyle get buttonMedium => const TextStyle(
        fontSize: 14,
        fontWeight: semiBold,
        color: AppColors.buttonText,
        height: 1.2,
      );

  // ============================================
  // Arabe — Cairo pour les titres, comme en français
  // ============================================
  //
  // Le corps de texte arabe n'a pas besoin d'un style à part : sans famille,
  // il prend l'arabe du système (SF Arabic, Noto Naskh), taillé pour être lu
  // petit. Les styles ci-dessous existent pour les écrans qui veulent la voix
  // de la marque en arabe, et ils sont légèrement plus aérés : l'arabe porte
  // ses diacritiques au-dessus et en dessous de la ligne.

  /// Arabic H1
  static TextStyle get h1Ar => TextStyle(
        fontFamily: fontFamilyTitle,
        fontSize: 28,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Arabic H2
  static TextStyle get h2Ar => TextStyle(
        fontFamily: fontFamilyTitle,
        fontSize: 24,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  /// Arabic H3
  static TextStyle get h3Ar => TextStyle(
        fontFamily: fontFamilyTitle,
        fontSize: 20,
        fontWeight: semiBold,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// Arabic H4
  static TextStyle get h4Ar => TextStyle(
        fontFamily: fontFamilyTitle,
        fontSize: 18,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// Arabic Body Large
  static TextStyle get bodyLargeAr => TextStyle(
        fontFamily: fontFamilyTitle,
        fontSize: 16,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  /// Arabic Body Medium
  static TextStyle get bodyMediumAr => TextStyle(
        fontFamily: fontFamilyTitle,
        fontSize: 14,
        fontWeight: regular,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  /// Arabic Body Small
  static TextStyle get bodySmallAr => TextStyle(
        fontFamily: fontFamilyTitle,
        fontSize: 12,
        fontWeight: regular,
        color: AppColors.textMuted,
        height: 1.6,
      );

  /// Arabic Button
  static TextStyle get buttonAr => const TextStyle(
        fontFamily: fontFamilyTitle,
        fontSize: 16,
        fontWeight: semiBold,
        color: AppColors.buttonText,
        height: 1.3,
      );

  // ============================================
  // Helper Methods
  // ============================================

  /// Get text style based on locale
  static TextStyle getLocalizedStyle(
      TextStyle frStyle, TextStyle arStyle, Locale locale) {
    return locale.languageCode == 'ar' ? arStyle : frStyle;
  }
}
