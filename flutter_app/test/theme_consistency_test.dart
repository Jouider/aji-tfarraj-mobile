import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Deux règles que l'œil ne sait pas vérifier, parce qu'il ne voit qu'un
/// thème à la fois.
///
/// Elles viennent toutes les deux de bugs réels, trouvés en regardant l'app en
/// thème clair après des semaines passées en sombre. À chaque fois le même
/// mécanisme : une valeur choisie pour un fond, appliquée à l'autre.
///
/// Un test qui lit le code source est inhabituel. Il est ici parce que le
/// défaut ne se voit ni à la compilation, ni à l'exécution, ni en relecture —
/// seulement en changeant de thème sur le bon écran, et il y en a dix-neuf.
void main() {
  final dartFiles = Directory('lib/features')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// Les occurrences de [pattern], avec leur fichier et leur ligne.
  List<String> findAll(RegExp pattern, {bool Function(String, int)? keep}) {
    final found = <String>[];
    for (final file in dartFiles) {
      final src = file.readAsStringSync();
      for (final m in pattern.allMatches(src)) {
        if (keep != null && !keep(src, m.start)) continue;
        final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
        found.add('${file.path}:$line');
      }
    }
    return found;
  }

  test('aucune ombre neutre écrite sur place', () {
    // Une ombre se lit par le contraste qu'elle creuse. Il faut 45 % de noir
    // pour qu'elle existe sur une page noire, et 8 % suffisent sur une page
    // blanche — au-delà, c'est un nuage sale. L'app en portait seize, de 4 %
    // à 40 %, et aucune ne regardait le thème : chacune était donc fausse
    // d'un côté ou de l'autre. `AppShadows.card` tranche une fois pour toutes.
    //
    // Les halos de marque (orange, or) ne sont pas concernés : une couleur
    // saturée se lit sur les deux fonds.
    final neutral = RegExp(
      r'boxShadow:\s*\[\s*BoxShadow\((?:[^()]|\([^()]*\))*?\)',
      dotAll: true,
    );

    final offenders = findAll(
      neutral,
      keep: (src, start) {
        final block = src.substring(start, (start + 400).clamp(0, src.length));
        return RegExp(r'Colors\.black|Color\(0xFF1A1A1A\)|Color\(0xFF000000\)'
                r'|Colors\.grey')
            .hasMatch(block.split(']').first);
      },
    );

    expect(
      offenders,
      isEmpty,
      reason: 'Ombre neutre écrite sur place — utilisez AppShadows.card, qui '
          'suit le thème :\n  ${offenders.join('\n  ')}',
    );
  });

  test("l'or n'est jamais écrit directement", () {
    // `AppColors.secondary` est un APLAT : on écrit dessus, pas avec. Écrit
    // sur la page claire il tombe à 1,89:1. Sur la page sombre il tient 10:1,
    // et c'est pour ça que cent quatre encres dorées ont vécu des mois sans
    // que personne ne les voie.
    //
    // `accentInk` pour la page, `accentInkOnPhoto` pour une affiche.
    final goldInk = RegExp(r'color\s*:\s*AppColors\.secondary\b(?!\w)');

    final offenders = findAll(
      goldInk,
      keep: (src, start) {
        final before = src.substring((start - 260).clamp(0, start), start);
        final fill = before.lastIndexOf('BoxDecoration(');
        final ink = [
          'Icon(',
          'TextStyle(',
          'copyWith(',
          'Indicator(',
        ].map(before.lastIndexOf).reduce((a, b) => a > b ? a : b);
        return ink > fill; // un aplat doré reste légitime
      },
    );

    expect(
      offenders,
      isEmpty,
      reason: "L'or utilisé comme encre — utilisez AppColors.accentInk :\n"
          '  ${offenders.join('\n  ')}',
    );
  });

  test('aucune famille de police hors du fichier typographie', () {
    // Cairo se demande par AppTypography, jamais à la main : c'est comme ça
    // qu'on se retrouve avec une graisse non embarquée, que Flutter remplace
    // silencieusement par la plus proche.
    final offenders = findAll(RegExp(r'fontFamily\s*:'));

    expect(offenders, isEmpty, reason: offenders.join('\n  '));
  });
}
