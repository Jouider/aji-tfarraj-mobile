import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Le glissement retour (bord gauche, iOS) ne fait que `pop` : il n'y a un
/// écran précédent que si l'on est venu par `push`.
///
/// `go` reconstruit la pile à partir de l'adresse. Vers un écran de détail,
/// il effaçait donc l'écran d'où l'on venait : ouvrir la réservation depuis
/// une émission, puis revenir sur l'émission, laissait le glissement sans
/// rien en dessous ; ouvrir une réservation depuis la liste changeait
/// d'onglet, sans retour possible.
void main() {
  test('les écrans de détail ne s\'ouvrent jamais avec go', () {
    const details = [
      'Routes.showReserve(',
      'Routes.episodeReserve(',
      'Routes.reservationDetail(',
    ];
    final offenders = <String>[];
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        // L'appel et sa cible peuvent être sur deux lignes.
        final call = lines[i] + (i + 1 < lines.length ? lines[i + 1] : '');
        if (RegExp(r'context\.go\(\s*$|context\.go\(').hasMatch(lines[i]) &&
            details.any(call.contains)) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Ouvrir un détail avec context.push.');
  });

  // La même disposition que l'app : l'émission et sa réservation dans
  // l'onglet Accueil, Explorer dans un autre.
  GoRouter replica() => GoRouter(initialLocation: '/home', routes: [
        StatefulShellRoute.indexedStack(
          builder: (c, s, nav) => nav,
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (c, s) => const Text('home')),
              GoRoute(
                path: '/show/:id',
                builder: (c, s) => const Text('show'),
                routes: [
                  GoRoute(
                      path: 'reserve',
                      builder: (c, s) => const Text('reserve')),
                ],
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/browse', builder: (c, s) => const Text('browse')),
            ]),
          ],
        ),
      ]);

  Future<String> visible(WidgetTester tester) async {
    await tester.pumpAndSettle();
    return ['home', 'show', 'reserve', 'browse']
        .firstWhere((n) => find.text(n).hitTestable().evaluate().isNotEmpty);
  }

  testWidgets('accueil → émission → réservation, puis retour, retour',
      (tester) async {
    final router = replica();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/show/1');
    await tester.pumpAndSettle();
    router.push('/show/1/reserve');
    expect(await visible(tester), 'reserve');

    router.pop();
    expect(await visible(tester), 'show');
    expect(router.canPop(), isTrue, reason: 'le glissement a encore où aller');
    router.pop();
    expect(await visible(tester), 'home');
  });

  testWidgets('une émission ouverte depuis Explorer y ramène', (tester) async {
    final router = replica();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/browse');
    await tester.pumpAndSettle();
    router.push('/show/2');
    expect(await visible(tester), 'show');

    router.pop();
    expect(await visible(tester), 'browse');
  });
}
