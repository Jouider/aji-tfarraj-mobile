import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/app/copywriting/wheel_copy.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart';
import 'package:aji_tfarraj/features/wheel/data/wheel_repository.dart';
import 'package:aji_tfarraj/features/wheel/domain/wheel.dart';
import 'package:aji_tfarraj/features/wheel/presentation/lucky_wheel_view.dart';
import 'package:aji_tfarraj/features/wheel/presentation/wheel_entry_card.dart';
import 'package:aji_tfarraj/features/wheel/presentation/wheel_painters.dart';
import 'package:aji_tfarraj/features/wheel/presentation/wheel_screen.dart';
import 'package:aji_tfarraj/features/wheel/presentation/wheel_sheets.dart';

/// La roue de la chance : l'app dessine, le serveur tire.
///
/// Ce qui doit tenir : la roue s'arrête sur la case que le serveur a
/// désignée — jamais sur une voisine —, les essais du jour reviennent passé
/// minuit, et rien ne s'affiche quand la roue est fermée.
void main() {
  Map<String, dynamic> json({
    bool enabled = true,
    int left = 3,
    DateTime? resetsAt,
  }) =>
      {
        'enabled': enabled,
        'daily_spins': 3,
        'spins_left': left,
        'resets_at': (resetsAt ?? DateTime.now().add(const Duration(hours: 5)))
            .toUtc()
            .toIso8601String(),
        'slices': [
          {'type': 'points', 'points': 5},
          {'type': 'retry', 'points': 0},
          {'type': 'points', 'points': 10},
          {'type': 'retry', 'points': 0},
          {'type': 'points', 'points': 50},
          {'type': 'reward', 'points': 0},
        ],
        'odds': [
          {'type': 'points', 'points': 5, 'percent': 50},
          {'type': 'points', 'points': 10, 'percent': 25},
          {'type': 'points', 'points': 50, 'percent': 0.5},
          {'type': 'retry', 'points': 0, 'percent': 24.4},
          {'type': 'reward', 'points': 0, 'percent': 0.1},
        ],
        'jackpot': {
          'id': 4,
          'title': 'Casquette 2M',
          'title_ar': 'قبعة 2M',
          'image_url': null,
          'available_today': true,
        },
        'points_balance': 120,
      };

  group('le modèle', () {
    test('lit la roue telle que le serveur la décrit', () {
      final s = WheelStatus.fromJson(json());

      expect(s.playable, isTrue);
      expect(s.slices.map((x) => x.type), [
        WheelOutcome.points,
        WheelOutcome.retry,
        WheelOutcome.points,
        WheelOutcome.retry,
        WheelOutcome.points,
        WheelOutcome.reward,
      ]);
      expect(s.odds.last.percent, 0.1);
      expect(s.jackpot!.titleFor(arabic: true), 'قبعة 2M');
      expect(s.pointsBalance, 120);
    });

    test('passé minuit, les essais sont revenus sans attendre le serveur', () {
      final reset = DateTime.now().add(const Duration(hours: 1));
      final s = WheelStatus.fromJson(json(left: 0, resetsAt: reset));

      expect(s.spinsLeftAt(DateTime.now()), 0);
      expect(s.spinsLeftAt(reset.add(const Duration(minutes: 1))), 3);
    });

    test('fermée, la roue ne se montre pas', () {
      expect(WheelStatus.fromJson(json(enabled: false)).playable, isFalse);
    });

    test('un tour met à jour les essais et le solde', () {
      final s = WheelStatus.fromJson(json());
      final after = s.after(const SpinResult(
        outcome: WheelOutcome.points,
        points: 10,
        slice: 2,
        spinsLeft: 2,
        pointsBalance: 130,
      ));

      expect(after.spinsLeft, 2);
      expect(after.pointsBalance, 130);
      expect(after.slices, same(s.slices));
    });
  });

  group('la géométrie', () {
    test('la rotation visée met bien la case sous le pointeur', () {
      for (final count in [4, 6, 8, 9]) {
        for (var i = 0; i < count; i++) {
          for (final offset in [0.21, 0.5, 0.79]) {
            final r = WheelGeometry.rotationFor(i, count, offset: offset);
            // Et ce, quel que soit le nombre de tours faits avant.
            expect(
                WheelGeometry.sliceUnderPointer(
                    r + 6 * 2 * 3.141592653589793, count),
                i,
                reason: '$count cases, case $i, décalage $offset');
          }
        }
      }
    });

    test('les pourcentages s\'écrivent à la française', () {
      expect(formatPercent(40, arabic: false), '40 %');
      expect(formatPercent(24.9, arabic: false), '24,9 %');
      expect(formatPercent(0.25, arabic: false), '0,25 %');
      expect(formatPercent(0.1, arabic: true), '0.1%');
    });
  });

  group('l\'écran', () {
    Future<void> pump(
      WidgetTester tester,
      Widget home, {
      required _FakeWheel Function() wheel,
      AppLocale locale = AppLocale.fr,
    }) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          stringsProvider.overrideWithValue(AppStrings(locale)),
          wheelProvider.overrideWith(wheel),
        ],
        child: MaterialApp(home: home),
      ));
      // Les ampoules clignotent sans fin : pas de pumpAndSettle ici.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> spinToTheEnd(WidgetTester tester, {int frames = 160}) async {
      await tester.tap(find.text('Tourner la roue'));
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    double rotation(WidgetTester tester) => tester
        .widget<LuckyWheelView>(find.byType(LuckyWheelView))
        .rotation
        .value;

    for (final target in [0, 2, 3, 5]) {
      testWidgets('la roue s\'arrête sur la case tirée ($target)',
          (tester) async {
        final status = WheelStatus.fromJson(json());
        final slice = status.slices[target];
        final result = SpinResult(
          outcome: slice.type,
          points: slice.points,
          slice: target,
          spinsLeft: 2,
          pointsBalance: 120 + slice.points,
          reward: slice.type == WheelOutcome.reward
              ? const WheelReward(id: 4, title: 'Casquette 2M')
              : null,
        );
        await pump(tester, const WheelScreen(),
            wheel: () => _FakeWheel(status, result));

        await spinToTheEnd(tester);

        expect(
          WheelGeometry.sliceUnderPointer(
              rotation(tester), status.slices.length),
          target,
        );
        const c = WheelCopyFr();
        expect(
          find.text(switch (slice.type) {
            WheelOutcome.points => c.winTitle(slice.points),
            WheelOutcome.retry => c.retryTitle,
            WheelOutcome.reward => c.jackpotTitle,
          }),
          findsOneWidget,
        );
        // Les essais ne baissent qu'une fois la roue arrêtée.
        expect(find.text(c.spinsLeft(2)), findsOneWidget);
      });
    }

    testWidgets('un refus du serveur ne laisse pas la roue désigner une case',
        (tester) async {
      final status = WheelStatus.fromJson(json());
      await pump(tester, const WheelScreen(),
          wheel: () => _FakeWheel(status, null,
              failure: ApiException(message: 'non', code: 'NO_SPINS_LEFT')));

      // Sans résultat, la roue finit sa course en un peu plus de deux
      // secondes ; le message reste quatre secondes.
      await spinToTheEnd(tester, frames: 60);

      expect(find.text(const WheelCopyFr().noSpinsLeft), findsOneWidget);
      expect(find.byType(WheelResultDialog), findsNothing);
    });

    testWidgets('plus d\'essai : on dit quand ils reviennent', (tester) async {
      final status = WheelStatus.fromJson(json(left: 0));
      await pump(tester, const WheelScreen(),
          wheel: () => _FakeWheel(status, null));

      expect(find.text('Tourner la roue'), findsNothing);
      expect(find.text('Reviens demain'), findsOneWidget);
      expect(find.textContaining('Nouveaux essais dans'), findsOneWidget);
    });

    testWidgets('les règles montrent les chances du serveur', (tester) async {
      final status = WheelStatus.fromJson(json());
      await pump(tester, const WheelScreen(),
          wheel: () => _FakeWheel(status, null));

      await tester.tap(find.text('Règles'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(WheelRulesSheet), findsOneWidget);
      expect(find.text('0,1 %'), findsOneWidget);
      expect(find.text('Gros lot : Casquette 2M'), findsOneWidget);
    });

    testWidgets('la carte d\'entrée invite à jouer', (tester) async {
      final status = WheelStatus.fromJson(json(left: 2));
      await pump(tester, const Scaffold(body: WheelEntryCard()),
          wheel: () => _FakeWheel(status, null));

      expect(find.text('Roue de la chance'), findsOneWidget);
      expect(find.text('2 essais gratuits aujourd\'hui'), findsOneWidget);
      expect(find.text('Jouer'), findsOneWidget);
    });

    testWidgets('fermée, la carte d\'entrée ne prend aucune place',
        (tester) async {
      final status = WheelStatus.fromJson(json(enabled: false));
      await pump(
        tester,
        const Scaffold(
          body: WheelEntryCard(padding: EdgeInsets.all(16)),
        ),
        wheel: () => _FakeWheel(status, null),
      );

      expect(find.text('Roue de la chance'), findsNothing);
      expect(
          find.byType(Padding).evaluate().where((e) {
            final w = e.widget as Padding;
            return w.padding == const EdgeInsets.all(16);
          }),
          isEmpty);
    });
  });

  test('le français et l\'arabe disent la même chose', () {
    for (final WheelCopy c in [const WheelCopyFr(), const WheelCopyAr()]) {
      for (final text in [
        c.title,
        c.entrySpinsLeft(3),
        c.spinsLeft(0),
        c.spinsLeft(1),
        c.nextSpinsIn(const Duration(hours: 2, minutes: 5)),
        c.rulesIntro(3),
        c.winTitle(10),
        c.retryBody(0),
        c.jackpotBody,
        c.noSpinsLeft,
      ]) {
        expect(text.trim(), isNotEmpty);
      }
    }
    expect(
        const WheelCopyFr().nextSpinsIn(const Duration(hours: 2, minutes: 5)),
        'Nouveaux essais dans 2 h 05');
  });
}

class _FakeWheel extends WheelNotifier {
  _FakeWheel(this.status, this.result, {this.failure});

  final WheelStatus status;
  final SpinResult? result;
  final Object? failure;

  @override
  Future<WheelStatus> build() async => status;

  @override
  Future<SpinResult> spin() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (failure != null) throw failure!;
    return result!;
  }

  @override
  void settle(SpinResult r) => state = AsyncData(status.after(r));
}
