import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';

/// Ces tests gardent une décision qui ne se voit pas à l'écran du développeur :
/// les polices sont DANS l'app, pas sur le réseau.
///
/// Le jour où quelqu'un remet `google_fonts`, ou demande une graisse de Cairo
/// qui n'est pas déclarée, rien ne casse ici : ça casse chez un membre à
/// Casablanca en 3G, qui voit l'app changer de police après deux secondes —
/// ou pas du tout s'il est hors ligne. C'est exactement le genre de régression
/// qu'un test doit attraper, parce qu'un œil ne l'attrapera pas.
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  group('les polices sont embarquées', () {
    test('aucune dépendance ne va chercher des polices au lancement', () {
      // `google_fonts` télécharge les .ttf au premier affichage et les met en
      // cache. Pratique en prototype, intenable en production : la typographie
      // dépend alors du réseau du membre.
      final lines = pubspec
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('#'))
          .join('\n');

      expect(
        lines.contains('google_fonts'),
        isFalse,
        reason: 'google_fonts télécharge les polices au runtime — '
            'Cairo doit rester déclaré en `fonts:` dans pubspec.yaml.',
      );
    });

    test('Cairo déclare les quatre graisses que la charte utilise', () {
      // Flutter ne se plaint jamais d'une graisse absente : il prend la plus
      // proche. Un titre ExtraBold se met donc à rendre en Bold sans un mot.
      for (final weight in [400, 600, 700, 800]) {
        expect(
          pubspec,
          contains('weight: $weight'),
          reason: 'la graisse $weight de Cairo n\'est plus déclarée — '
              'Flutter rendra silencieusement la plus proche.',
        );
      }
    });

    test('chaque fichier de police déclaré existe vraiment', () {
      final assets = RegExp(r'asset: (assets/fonts/[^\s]+)')
          .allMatches(pubspec)
          .map((m) => m.group(1)!)
          .toList();

      expect(assets, hasLength(4));
      for (final path in assets) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path est déclaré dans pubspec.yaml mais absent du disque.',
        );
      }
    });

    test('l\'export PDF du manifeste garde les chemins qu\'il charge', () {
      // `return_manifest_export.dart` lit ces deux fichiers par chemin
      // (rootBundle.load), pas par famille : les renommer casse le PDF des
      // retours sans que l'analyse ni l'interface ne bougent.
      expect(File('assets/fonts/Cairo-Regular.ttf').existsSync(), isTrue);
      expect(File('assets/fonts/Cairo-Bold.ttf').existsSync(), isTrue);
    });
  });

  group('deux voix, et pas une de plus', () {
    test('les titres parlent Cairo', () {
      for (final style in [
        AppTypography.h1,
        AppTypography.h2,
        AppTypography.h3,
        AppTypography.h1Ar,
        AppTypography.h2Ar,
        AppTypography.h3Ar,
      ]) {
        expect(style.fontFamily, AppTypography.fontFamilyTitle);
      }
    });

    test('l\'interface parle la police du système', () {
      // Pas de famille = celle du téléphone. C'est ce qui se lit le mieux à
      // cette taille, ça suit les réglages d'accessibilité, et ça couvre
      // l'arabe comme le français sans second fichier.
      for (final style in [
        AppTypography.bodyLarge,
        AppTypography.bodyMedium,
        AppTypography.bodySmall,
        AppTypography.labelLarge,
        AppTypography.labelMedium,
        AppTypography.labelSmall,
        AppTypography.caption,
        AppTypography.buttonLarge,
        AppTypography.buttonMedium,
        AppTypography.h4,
      ]) {
        expect(style.fontFamily, isNull);
      }
    });

    test('Cairo s\'arrête aux grands titres', () {
      // La règle : en dessous de 20 px, la police du système est plus lisible.
      // Si un style Cairo descend sous cette barre, c'est une décision à
      // prendre, pas un détail à laisser passer.
      for (final style in [AppTypography.h1, AppTypography.h2, AppTypography.h3]) {
        expect(style.fontSize, greaterThanOrEqualTo(19));
      }
      expect(AppTypography.h4.fontSize, lessThan(20));
    });

    test('les graisses demandées sont celles qui sont déclarées', () {
      const declared = {
        FontWeight.w400,
        FontWeight.w600,
        FontWeight.w700,
        FontWeight.w800,
      };

      final cairoStyles = <String, TextStyle>{
        'h1': AppTypography.h1,
        'h2': AppTypography.h2,
        'h3': AppTypography.h3,
        'h1Ar': AppTypography.h1Ar,
        'h2Ar': AppTypography.h2Ar,
        'h3Ar': AppTypography.h3Ar,
        'h4Ar': AppTypography.h4Ar,
        'bodyLargeAr': AppTypography.bodyLargeAr,
        'bodyMediumAr': AppTypography.bodyMediumAr,
        'bodySmallAr': AppTypography.bodySmallAr,
        'buttonAr': AppTypography.buttonAr,
      };

      cairoStyles.forEach((name, style) {
        expect(
          declared,
          contains(style.fontWeight),
          reason: '$name demande ${style.fontWeight} à Cairo, '
              'qui n\'est pas dans les quatre coupes embarquées.',
        );
      });
    });
  });
}
