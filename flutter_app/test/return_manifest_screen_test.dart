// La feuille de retour, à l'écran.
//
// Ce qui doit tenir : sous les totaux, le détail par arrêt et le nom des
// personnes qui attendent — c'est la seule chose que le chauffeur emporte.
// Un écran qui n'affiche que trois nombres ne sert à personne.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;
import 'package:aji_tfarraj/features/staff/data/staff_repository.dart';
import 'package:aji_tfarraj/features/staff/domain/return_manifest.dart';
import 'package:aji_tfarraj/features/staff/presentation/return_manifest_screen.dart';

ReturnManifest _manifest() => ReturnManifest.fromJson({
      'episode': {
        'id': 42,
        'title': 'episode 1',
        'starts_at': '2026-09-23T22:00:00',
        'studio': 'Studio 2M Ain Sebaa',
        'city': 'Casablanca',
      },
      'show': {'id': 1, 'title': 'Soirées électorales 2026'},
      'generated_at': '2026-09-23T23:40:00',
      'has_shuttle': true,
      'totals': {
        'checked_in_people': 70,
        'checked_in_tickets': 70,
        'riders': 50,
        'own_means': 20,
      },
      'points': [
        {
          'id': 1,
          'name': 'Gare Casa-Port',
          'landmark': 'devant la pharmacie',
          'served': true,
          'people': 30,
          'tickets': 30,
          'passengers': [
            {'name': 'Ahmed Bennani', 'seats': 1},
            {'name': 'Salma Idrissi', 'seats': 1},
          ],
        },
        {
          'id': 2,
          'name': 'Ain Diab',
          'served': true,
          'people': 20,
          'tickets': 20,
          'passengers': [
            {'name': 'Youssef Alami', 'seats': 1},
          ],
        },
      ],
    });

Future<void> _pump(WidgetTester tester, ReturnManifest manifest) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        returnManifestProvider(42).overrideWith((ref) async => manifest),
      ],
      child: const MaterialApp(
        home: ReturnManifestScreen(episodeId: 42),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('sous les totaux, chaque arrêt et son effectif', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await _pump(tester, _manifest());

    // Les totaux.
    expect(find.text('50'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);

    // Et surtout le détail, sans lequel l'écran ne sert à rien.
    expect(find.text('Gare Casa-Port'), findsOneWidget);
    expect(find.text('devant la pharmacie'), findsOneWidget);
    expect(find.text('Ain Diab'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('20'), findsNWidgets(2), reason: 'le total et l\'arrêt');
    expect(tester.takeException(), isNull);
  });

  testWidgets('déplier un arrêt nomme les personnes qui attendent',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await _pump(tester, _manifest());

    expect(find.text('Ahmed Bennani'), findsNothing);

    await tester.tap(find.text('Gare Casa-Port'));
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Bennani'), findsOneWidget);
    expect(find.text('Salma Idrissi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  /// Un arrêt desservi où personne n'attend allonge la feuille sans rien
  /// apprendre au chauffeur — et le PDF ne l'imprimait déjà pas.
  testWidgets('un arrêt sans personne n\'est pas affiché', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final manifest = ReturnManifest.fromJson({
      'episode': {'id': 42, 'title': 'episode 1'},
      'show': {'id': 1, 'title': 'Soirées électorales 2026'},
      'has_shuttle': true,
      'totals': {
        'checked_in_people': 30,
        'checked_in_tickets': 30,
        'riders': 30,
        'own_means': 0,
      },
      'points': [
        {
          'id': 1,
          'name': 'Gare Casa-Port',
          'served': true,
          'people': 30,
          'tickets': 30,
          'passengers': [
            {'name': 'Ahmed Bennani', 'seats': 1},
          ],
        },
        {
          'id': 2,
          'name': 'Arrêt désert',
          'served': true,
          'people': 0,
          'tickets': 0,
          'passengers': [],
        },
      ],
    });

    await _pump(tester, manifest);

    expect(find.text('Gare Casa-Port'), findsOneWidget);
    expect(find.text('Arrêt désert'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  /// Le partage ne doit pas partir pendant que la feuille de choix se referme.
  ///
  /// Sur iOS, présenter le panneau de partage tant que la feuille précédente
  /// s'en va est refusé sans un mot : le PDF échouait sur « Impossible de
  /// préparer la feuille », et « envoyer en message » ne faisait rien du tout.
  testWidgets('le partage attend la fermeture de la feuille de choix',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    var shareCalls = 0;

    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      shareCalls++;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    await _pump(tester, _manifest());

    const s = AppStrings(AppLocale.fr);
    await tester.tap(find.text(s.staffManifestShare));
    await tester.pumpAndSettle();
    expect(find.text(s.staffManifestShareText), findsOneWidget,
        reason: 'la feuille de choix est ouverte');

    await tester.tap(find.text(s.staffManifestShareText));

    // Pendant la fermeture : rien ne part.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(shareCalls, 0,
        reason: 'partager pendant la fermeture est refusé par iOS');

    // Une fois la feuille partie : le partage s'ouvre.
    await tester.pump(const Duration(milliseconds: 600));
    expect(shareCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
