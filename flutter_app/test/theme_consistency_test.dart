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
    // `color:` n'est pas le seul nom que prend une encre. `iconColor`,
    // `valueColor`… : dix-sept de plus se cachaient derrière ces alias, dont
    // les icônes de la carte de billet — dorées sur fond blanc.
    final goldInk = RegExp(
      r'\b(color|iconColor|textColor|labelColor|titleColor|valueColor'
      r'|accentColor|tintColor)\s*:\s*AppColors\.secondary\b(?!\w)',
    );

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

  test('tout écran du shell dégage la barre d\'onglets', () {
    // Le shell pose la barre d'onglets PAR-DESSUS le contenu
    // (`extendBody: true`), pour que les affiches défilent sous le verre. En
    // échange, tout écran d'onglet doit réserver sa centaine de points en bas,
    // sinon son dernier élément passe derrière elle.
    //
    // C'est invisible en relecture, et ça s'est produit trois fois : le bouton
    // « Enregistrer » du profil, les actions d'une réservation et la dernière
    // affiche de l'accueil étaient tous sous la barre. Ce dernier portait même
    // le commentaire « FIX: Bottom padding — 16px before bottom nav », seize
    // points là où il en fallait cent deux.
    //
    // Deux façons légitimes de s'en acquitter : appeler
    // `AppSpacing.navBarClearance`, ou lire l'inset soi-même pour une barre
    // collée en bas. N'en faire aucune est le bug.
    const shellScreens = [
      'lib/features/home/home_screen.dart',
      'lib/features/show/show_detail_screen.dart',
      'lib/features/reservation/reserve_seats_screen.dart',
      'lib/features/reservation/reservation_detail_screen.dart',
      'lib/features/reservation/my_reservations_screen.dart',
      'lib/features/profile/presentation/edit_profile_screen.dart',
      'lib/features/profile/profile_screen.dart',
      'lib/features/shows/presentation/shows_browse_screen.dart',
      'lib/features/ticket/ticket_screen.dart',
    ];

    final offenders = <String>[];
    for (final path in shellScreens) {
      final file = File(path);
      expect(file.existsSync(), isTrue,
          reason: '$path a bougé — mettez cette liste à jour.');

      final src = file.readAsStringSync();
      if (!src.contains('navBarClearance') && !src.contains('padding.bottom')) {
        offenders.add(path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: "Écran d'onglet sans dégagement en bas — ajoutez "
          'AppSpacing.navBarClearance(context) au bas de son padding :\n'
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
