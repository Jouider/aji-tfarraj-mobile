import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/shadows.dart';

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
  _accentInkTests();
  _shadowTests();
  _premiumTests();

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

    /// L'étiquette d'une chaîne n'a pas de flou : le voile est tout ce qui
    /// sépare son encre blanche de l'affiche. Et elle apparaît sur trois
    /// écrans, donc sur toutes les affiches du catalogue — y compris les
    /// claires.
    test('une étiquette de chaîne se lit sur n\'importe quelle affiche', () {
      for (final brightness in [Brightness.dark, Brightness.light]) {
        AppColors.updateBrightness(brightness);

        final worst = Color.alphaBlend(
          AppColors.glassOnPhotoSolid,
          const Color(0xFFFFFFFF), // l'affiche la plus claire possible
        );

        expect(
          contrast(AppColors.inkOnPhoto, worst),
          greaterThanOrEqualTo(4.5),
          reason: 'À 42 %, le voile laissait le blanc tomber à 3,0:1 sur une '
              'affiche claire — la pastille MEDI1 sur la carte rose.',
        );
      }
    });

    /// La même étiquette posée sur une carte : là, la surface est connue, et
    /// c'est le gris de la page qui s'applique — pas le voile des affiches.
    test('posée sur une carte, elle se lit dans les deux thèmes', () {
      for (final brightness in [Brightness.dark, Brightness.light]) {
        AppColors.updateBrightness(brightness);

        expect(
          contrast(AppColors.textSecondary, AppColors.backgroundGrey),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

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

/// ─────────────────────────────────────────────────────────────────────────
/// L'or : un aplat, pas une encre
/// ─────────────────────────────────────────────────────────────────────────
///
/// [AppColors.secondary] est fait pour qu'on écrive DESSUS, pas AVEC. Écrit
/// sur la page claire, il tombe à 1,89:1 — « Voir tout » était dans ce cas,
/// et soixante-dix autres libellés et icônes avec lui. Sur la page sombre il
/// tenait 10:1, ce qui explique que personne ne l'ait vu.
void _accentInkTests() {
  group('l\'encre dorée', () {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      final name = brightness == Brightness.dark ? 'sombre' : 'clair';

      test('en thème $name, elle se lit sur la page', () {
        AppColors.updateBrightness(brightness);

        expect(
          contrast(AppColors.accentInk, AppColors.backgroundWhite),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('en thème $name, elle se lit sur une carte', () {
        AppColors.updateBrightness(brightness);

        expect(
          contrast(AppColors.accentInk, AppColors.backgroundLight),
          greaterThanOrEqualTo(4.5),
        );
      });
    }

    /// L'erreur exacte que ce jeton répare.
    test('l\'or brut ne se lit pas sur la page claire', () {
      AppColors.updateBrightness(Brightness.light);

      expect(
        contrast(AppColors.secondary, AppColors.backgroundWhite),
        lessThan(3.0),
        reason: 'C\'est pour ça qu\'accentInk existe : ne jamais écrire '
            'directement avec AppColors.secondary sur une surface de page.',
      );
    });

    /// Sur une affiche, en revanche, l'or reste l'or : le voile est sombre
    /// dans les deux thèmes.
    test('sur une affiche, l\'or ne bouge pas et reste lisible', () {
      AppColors.updateBrightness(Brightness.light);
      final light = AppColors.accentInkOnPhoto;
      AppColors.updateBrightness(Brightness.dark);

      expect(AppColors.accentInkOnPhoto, light);

      // Le fond n'est pas « une affiche quelconque » : l'or n'est écrit sur
      // une affiche que dans le bandeau du héros, où le voile de lisibilité
      // atteint 85 % de noir. Même sur l'affiche la plus claire possible, le
      // fond y reste à 38.
      final heroScrim = Color.alphaBlend(
        const Color(0xD9000000),
        const Color(0xFFFFFFFF),
      );
      expect(
        contrast(AppColors.accentInkOnPhoto, heroScrim),
        greaterThanOrEqualTo(4.5),
        reason: 'L\'or n\'est une encre acceptable que sous le voile du '
            'héros. Hors de ce voile, un verre à 34 % le laisse tomber à '
            '1,2:1 — d\'où la note sur GlassPill.',
      );
    });
  });

  tearDown(() => AppColors.updateBrightness(Brightness.dark));
}

/// ─────────────────────────────────────────────────────────────────────────
/// Les ombres
/// ─────────────────────────────────────────────────────────────────────────
///
/// Une ombre se lit par le contraste qu'elle creuse avec la page. Les 45 % de
/// noir qu'il faut sur une page noire donnaient, sur une page blanche, un
/// nuage sombre sous chaque carte — et comme les cartes ne sont espacées que
/// de 14 points, les nuages se rejoignaient en une plaque continue.
void _shadowTests() {
  group('l\'ombre des cartes', () {
    test('elle est bien plus discrète sur une page claire', () {
      AppColors.updateBrightness(Brightness.dark);
      final dark = AppShadows.card.first.color.a;

      AppColors.updateBrightness(Brightness.light);
      final light = AppShadows.card.first.color.a;

      expect(
        light,
        lessThan(dark / 3),
        reason: 'La même opacité des deux côtés, c\'est la plaque grise '
            'sous la rangée de cartes.',
      );
      expect(light, lessThanOrEqualTo(0.12));
    });
  });

  tearDown(() => AppColors.updateBrightness(Brightness.dark));
}

/// La carte noire à filet doré, celle qui remplace l'aplat jaune.
///
/// Elle n'existe que parce que l'or, en GRANDE surface, n'accepte que l'encre
/// noire : le blanc n'y mesure que 2,1:1. Ces tests vérifient que le
/// renversement tient sa promesse — le blanc et l'or se lisent tous deux sur
/// le noir — et, surtout, que la carte reste la même dans les deux thèmes.
void _premiumTests() {
  group('la carte premium', () {
    // Le dégradé va du haut relevé au fond : l'encre doit tenir aux DEUX
    // bouts, pas seulement sur la moyenne.
    final grounds = {
      'son fond': AppColors.premiumSurface,
      'son haut relevé': AppColors.premiumSurfaceRaised,
    };

    grounds.forEach((where, ground) {
      test('le titre blanc se lit sur $where', () {
        expect(contrast(AppColors.inkOnPhoto, ground),
            greaterThanOrEqualTo(4.5));
      });

      test('l\'accent doré se lit sur $where', () {
        expect(contrast(AppColors.secondary, ground),
            greaterThanOrEqualTo(4.5));
      });
    });

    test('elle ne change pas avec le thème', () {
      // C'est un OBJET, pas une surface de page : si elle suivait le thème,
      // elle redeviendrait une carte claire en thème clair et le filet doré
      // n'aurait plus rien à border.
      AppColors.updateBrightness(Brightness.dark);
      final dark = AppColors.premiumSurface;
      AppColors.updateBrightness(Brightness.light);

      expect(AppColors.premiumSurface, dark);
    });

    /// L'erreur exacte que cette carte répare.
    test('le blanc ne tenait pas sur l\'aplat doré qu\'elle remplace', () {
      expect(contrast(AppColors.inkOnPhoto, AppColors.secondary), lessThan(3));
    });

    test('et le même or, posé sur le noir, passe largement', () {
      expect(
        contrast(AppColors.secondary, AppColors.premiumSurface),
        greaterThan(contrast(AppColors.inkOnPhoto, AppColors.secondary)),
      );
    });
  });

  tearDown(() => AppColors.updateBrightness(Brightness.dark));
}
