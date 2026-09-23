// Le retour après le tournage : l'arrêt où la navette dépose la personne.
//
// La même liste sert à trois endroits — la réservation, la porte, l'inscription
// sur place. Ce qui doit tenir : une liste vide ne pose pas la question (pas de
// navette ce soir-là), le refus est une réponse comme une autre, et un épisode
// d'un serveur qui ne connaît pas encore les arrêts ne casse rien.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/return_points/domain/return_point_option.dart';
import 'package:aji_tfarraj/features/return_points/presentation/return_point_choice.dart';
import 'package:aji_tfarraj/features/return_points/presentation/return_point_field.dart';
import 'package:aji_tfarraj/features/shows/domain/episode.dart';

Map<String, dynamic> _stop(int id, String name, {String? ar, String? landmark}) =>
    {'id': id, 'name': name, 'name_ar': ar, 'landmark': landmark};

void main() {
  const s = AppStrings(AppLocale.fr);

  final points = [
    ReturnPointOption.fromJson(
        _stop(1, 'Gare Casa-Port', ar: 'محطة كازا-بور', landmark: 'devant la pharmacie')),
    ReturnPointOption.fromJson(_stop(2, 'Ain Diab')),
  ];

  group('ce que le serveur annonce', () {
    test('les arrêts arrivent avec leur repère et leur nom arabe', () {
      expect(points.first.localizedName(false), 'Gare Casa-Port');
      expect(points.first.localizedName(true), 'محطة كازا-بور');
      expect(points.first.landmark, 'devant la pharmacie');
    });

    test('un arrêt sans nom arabe retombe sur le français', () {
      expect(points[1].localizedName(true), 'Ain Diab');
    });

    test('rien, une liste vide ou du bruit ne donnent aucun arrêt', () {
      for (final json in <Object?>[null, <dynamic>[], 'nope', <dynamic>[42, 'x']]) {
        expect(ReturnPointOption.listFrom(json), isEmpty, reason: '$json');
      }
    });
  });

  group('l\'épisode', () {
    Episode parse(Map<String, dynamic> json) => Episode.fromJson({
          'id': 7,
          'title': 'Tournage',
          'city': 'Casablanca',
          'capacity': 100,
          'reserved_seats': 10,
          ...json,
        });

    test('porte les arrêts desservis ce soir-là', () {
      final episode = parse({
        'return_points': [_stop(1, 'Gare Casa-Port'), _stop(2, 'Ain Diab')],
      });

      expect(episode.returnPoints, hasLength(2));
      expect(episode.returnPoints.first.name, 'Gare Casa-Port');
    });

    /// Un serveur d'avant la fonction n'envoie rien : pas de navette, donc pas
    /// de question — et surtout pas une erreur.
    test('sans arrêts annoncés, il n\'y a pas de navette', () {
      expect(parse({}).returnPoints, isEmpty);
      expect(parse({'return_points': []}).returnPoints, isEmpty);
    });

    test('ce qui est lu se relit après un aller-retour par le cache', () {
      final episode = parse({'return_points': [_stop(3, 'Sidi Maarouf')]});

      expect(Episode.fromJson(episode.toJson()).returnPoints.single.name,
          'Sidi Maarouf');
    });
  });

  group('le choix, à l\'écran', () {
    Future<int?> pump(
      WidgetTester tester, {
      required List<ReturnPointOption> points,
      int? selectedId,
    }) async {
      int? chosen;
      var called = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReturnPointChoice(
            points: points,
            selectedId: selectedId,
            isArabic: false,
            noneLabel: s.returnPointNone,
            onChoose: (id) {
              chosen = id;
              called = true;
            },
          ),
        ),
      ));

      return called ? chosen : null;
    }

    testWidgets('une ligne par arrêt, plus « par mes propres moyens »',
        (tester) async {
      await pump(tester, points: points);

      expect(find.text('Gare Casa-Port'), findsOneWidget);
      expect(find.text('devant la pharmacie'), findsOneWidget);
      expect(find.text('Ain Diab'), findsOneWidget);
      expect(find.text(s.returnPointNone), findsOneWidget,
          reason: 'refuser la navette est une réponse, pas une absence');
    });

    /// Pas de navette ce soir-là : la question ne se pose pas du tout.
    testWidgets('sans arrêt, rien ne s\'affiche', (tester) async {
      await pump(tester, points: const []);

      expect(find.text(s.returnPointNone), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('le choix en cours est marqué', (tester) async {
      await pump(tester, points: points, selectedId: 2);

      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
    });

    testWidgets('taper un arrêt le remonte, taper le refus remonte null',
        (tester) async {
      int? chosen;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ReturnPointChoice(
              points: points,
              selectedId: chosen,
              isArabic: false,
              noneLabel: s.returnPointNone,
              onChoose: (id) => setState(() => chosen = id),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Ain Diab'));
      await tester.pumpAndSettle();
      expect(chosen, 2);

      await tester.tap(find.text(s.returnPointNone));
      await tester.pumpAndSettle();
      expect(chosen, isNull);
    });
  });

  group('la ligne repliée, à la réservation', () {
    // Dix arrêts déroulés poussaient les conditions et le bouton hors de
    // l'écran : la liste ne s'ouvre plus que si on la demande.
    Future<int?> pump(WidgetTester tester, {int? selectedId}) async {
      int? chosen = selectedId;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ReturnPointField(
              points: points,
              selectedId: chosen,
              isArabic: false,
              strings: s,
              onChoose: (id) => setState(() => chosen = id),
            ),
          ),
        ),
      ));

      return chosen;
    }

    testWidgets('elle tient sur une ligne, sans dérouler les arrêts',
        (tester) async {
      await pump(tester);

      expect(find.text(s.returnPointQuestion), findsOneWidget);
      expect(find.text(s.returnPointNone), findsOneWidget,
          reason: 'la réponse par défaut est affichée, pas un champ vide');
      expect(find.text('Gare Casa-Port'), findsNothing);
      expect(find.text('Ain Diab'), findsNothing);
    });

    testWidgets('elle montre l\'arrêt déjà choisi', (tester) async {
      await pump(tester, selectedId: 1);

      expect(find.text('Gare Casa-Port'), findsOneWidget);
      expect(find.text(s.returnPointNone), findsNothing);
    });

    testWidgets('la liste s\'ouvre au toucher, et se referme sur le choix',
        (tester) async {
      await pump(tester);

      await tester.tap(find.text(s.returnPointChange));
      await tester.pumpAndSettle();

      expect(find.text('Gare Casa-Port'), findsOneWidget);
      expect(find.text('Ain Diab'), findsOneWidget);

      await tester.tap(find.text('Ain Diab'));
      await tester.pumpAndSettle();

      // La feuille est refermée, et la ligne porte le nouveau choix.
      expect(find.text('Gare Casa-Port'), findsNothing);
      expect(find.text('Ain Diab'), findsOneWidget);
    });

    testWidgets('sans navette, rien ne s\'affiche', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ReturnPointField(
            points: const [],
            selectedId: null,
            isArabic: false,
            strings: s,
            onChoose: (_) {},
          ),
        ),
      ));

      expect(find.text(s.returnPointQuestion), findsNothing);
    });
  });
}
