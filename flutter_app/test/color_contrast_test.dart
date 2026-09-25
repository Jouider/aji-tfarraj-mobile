import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';

/// Contrast is measurable, so it should be measured rather than eyeballed.
///
/// This exists because the gold call-to-action shipped white-on-gold at 2.1:1 —
/// unreadable, and below the floor even for large text. It looked fine to
/// whoever wrote it, because in the *dark* theme the token happened to resolve
/// to near-black. The light theme had the same button in white.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;

  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  /// WCAG AA: 4.5:1 for body text, 3:1 for large text. Button labels are large
  /// and bold, but a CTA is the last thing that should be borderline.
  const aaNormalText = 4.5;

  _glassTests();

  group('ink on the gold call-to-action', () {
    test('is readable, and by a wide margin', () {
      expect(
        contrast(AppColors.secondary, AppColors.onSecondary),
        greaterThanOrEqualTo(aaNormalText),
      );
    });

    /// The exact mistake this guard exists for.
    test('white would not be — hence the dedicated token', () {
      expect(
        contrast(AppColors.secondary, const Color(0xFFFFFFFF)),
        lessThan(3.0),
        reason: 'white on the gold is ~2.1:1; never use it',
      );
    });

    /// [AppColors.secondary] is one constant for both themes, so its ink must
    /// be too. A theme-dependent token here is what broke it last time.
    test('neither colour moves with the theme', () {
      const gold = AppColors.secondary;
      const ink = AppColors.onSecondary;

      // Both are compile-time constants; if either became a getter this stops
      // compiling, which is the point.
      expect(gold, isA<Color>());
      expect(ink, isA<Color>());
    });
  });

  group('ink on the orange call-to-action', () {
    /// Le dégradé de la charte ne supporte aucune encre d'un bout à l'autre :
    /// le blanc tombe à 3,1:1 sur l'orange clair, l'encre noire à 3,3:1 sur le
    /// rouge foncé. C'est la raison d'être d'un dégradé de bouton distinct, et
    /// ce test le rappelle à qui voudrait les réunir.
    test('the charter gradient carries no ink from end to end', () {
      // Les deux seules encres envisageables, chacune à son pire bout.
      const white = Color(0xFFF7F8F8);
      const dark = Color(0xFF0C0C0C);

      expect(contrast(AppColors.primary, white), lessThan(aaNormalText),
          reason: 'le blanc lâche sur l\'orange clair');
      expect(contrast(AppColors.primaryDark, dark), lessThan(aaNormalText),
          reason: 'l\'encre sombre lâche sur le rouge foncé');
    });

    test('the button gradient is readable at both ends', () {
      for (final end in [AppColors.primaryAction, AppColors.primaryDark]) {
        expect(
          contrast(end, AppColors.onPrimary),
          greaterThanOrEqualTo(aaNormalText),
          reason: 'un libellé de bouton se lit sur toute la longueur',
        );
      }
    });

    /// Ce qui reste vrai quoi qu'il arrive : le blanc n'a rien à faire sur
    /// l'orange clair, et l'encre noire rien à faire sur le rouge foncé.
    test('the two inks are never interchangeable', () {
      expect(
        contrast(AppColors.primary, const Color(0xFFFFFFFF)),
        lessThan(aaNormalText),
      );
      expect(
        contrast(AppColors.primaryDark, const Color(0xFFF7F8F8)),
        greaterThanOrEqualTo(aaNormalText),
        reason: 'le rouge foncé, lui, porte le blanc — pour un aplat uni',
      );
    });
  });
}

/// ─────────────────────────────────────────────────────────────────────────
/// Le verre
/// ─────────────────────────────────────────────────────────────────────────
///
/// Une surface translucide n'a pas de couleur : elle a un INTERVALLE de
/// couleurs, borné par son opacité. Un voile d'alpha `a` posé sur n'importe
/// quoi donne un fond entre `a × voile` et `a × voile + (1-a) × blanc`, et
/// c'est le pire bout qui décide si le libellé se lit.
///
/// C'est ce qui a rendu les onglets inactifs invisibles : le voile noir à 34 %
/// laissait le fond monter à 168 dès qu'une affiche claire passait sous la
/// barre, et le gris des libellés y tombait à 1,6:1. À l'œil, sur une page
/// sombre, tout allait bien.
void _glassTests() {
  /// Le pire fond possible derrière un voile : le blanc pour un voile sombre,
  /// le noir pour un voile clair.
  Color worstCaseBehind(Color veil) {
    final backdrop = veil.computeLuminance() < 0.5
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);

    return Color.alphaBlend(veil, backdrop);
  }

  group('le verre de la barre', () {
    /// 4,5:1 : les libellés font 9,5 px, c'est du petit texte.
    const aaNormalText = 4.5;

    for (final brightness in [Brightness.dark, Brightness.light]) {
      final name = brightness == Brightness.dark ? 'sombre' : 'clair';

      test('en thème $name, un onglet inactif reste lisible sur une affiche',
          () {
        AppColors.updateBrightness(brightness);

        final worst = worstCaseBehind(AppColors.glassSurface);

        expect(
          contrast(AppColors.textSecondary, worst),
          greaterThanOrEqualTo(4.0),
          reason: 'Fond au pire ${worst.value.toRadixString(16)} : le voile '
              'est trop transparent, l\'affiche derrière reprend le dessus.',
        );
      });

      test('en thème $name, l\'onglet actif ne dépend pas de l\'affiche', () {
        AppColors.updateBrightness(brightness);

        // La capsule est opaque : c'est elle le fond, pas ce qui défile.
        expect(
          AppColors.glassHighlight.a,
          1.0,
          reason: 'Une capsule translucide rend la couleur de l\'onglet actif '
              'dépendante de l\'image derrière — c\'est ce qui faisait tomber '
              'l\'or à 2,3:1.',
        );

        expect(
          contrast(AppColors.glassAccent, AppColors.glassHighlight),
          greaterThanOrEqualTo(aaNormalText),
        );
      });
    }

    test('le verre de la page suit le thème, celui des affiches jamais', () {
      AppColors.updateBrightness(Brightness.dark);
      final pageDark = AppColors.glassSurface;
      final photoDark = AppColors.glassOnPhoto;

      AppColors.updateBrightness(Brightness.light);

      expect(
        AppColors.glassSurface,
        isNot(pageDark),
        reason: 'Le voile noir posé sur une page blanche ne fait pas du verre, '
            'il fait une plaque grise.',
      );
      expect(
        AppColors.glassOnPhoto,
        photoDark,
        reason: 'Une affiche n\'a pas de thème : son voile reste sombre, '
            'sinon l\'encre blanche écrite dessus disparaît.',
      );
    });
  });

  tearDown(() => AppColors.updateBrightness(Brightness.dark));
}
