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
import 'package:aji_tfarraj/features/rewards/data/rewards_repository.dart';
import 'package:aji_tfarraj/features/rewards/presentation/rewards_screen.dart';
import 'package:aji_tfarraj/features/tutorials/data/tutorials_repository.dart'
    show appConfigJsonProvider;
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
    int adLeft = 0,
    bool adSpins = false,
    DateTime? resetsAt,
  }) =>
      {
        'enabled': enabled,
        'daily_spins': 3,
        'spins_left': left,
        'ad_spins_left': adLeft,
        'ad_spins_enabled': adSpins,
        'free_spins': adSpins ? 1 : 3,
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
      expect(s.jackpot!.titleFor(arabic: true), 'قبعة 2M');
      expect(s.pointsBalance, 120);
    });

    test('passé minuit, les essais sont revenus sans attendre le serveur', () {
      final reset = DateTime.now().add(const Duration(hours: 1));
      final s = WheelStatus.fromJson(json(left: 0, resetsAt: reset));

      expect(s.spinsLeftAt(DateTime.now()), 0);
      expect(s.spinsLeftAt(reset.add(const Duration(minutes: 1))), 3);
    });

    test('après l\'essai gratuit, une vidéo débloque le suivant', () {
      final s = WheelStatus.fromJson(json(left: 0, adLeft: 2, adSpins: true));
      final now = DateTime.now();

      expect(s.spinsLeftAt(now), 0);
      expect(s.adSpinsLeftAt(now), 2);
      expect(s.videoUnlocksSpinAt(now), isTrue);
    });

    test('plus aucune vidéo à regarder : c\'est fini pour aujourd\'hui', () {
      final s = WheelStatus.fromJson(json(left: 0, adSpins: true));
      expect(s.videoUnlocksSpinAt(DateTime.now()), isFalse);
    });

    test('passé minuit, seuls les essais gratuits reviennent tout de suite',
        () {
      final reset = DateTime.now().add(const Duration(hours: 1));
      final s = WheelStatus.fromJson(
          json(left: 0, adLeft: 0, adSpins: true, resetsAt: reset));
      final later = reset.add(const Duration(minutes: 1));

      expect(s.spinsLeftAt(later), 1);
      expect(s.adSpinsLeftAt(later), 2);
    });

    test('un ancien serveur, sans les champs vidéo, reste tout gratuit', () {
      final s = WheelStatus.fromJson(json()
        ..remove('ad_spins_left')
        ..remove('ad_spins_enabled')
        ..remove('free_spins'));

      expect(s.adSpinsEnabled, isFalse);
      expect(s.freeSpins, 3);
      expect(s.videoUnlocksSpinAt(DateTime.now()), isFalse);
    });

    test('après le tour, le résultat dit s\'il reste une vidéo à regarder',
        () {
      final r = SpinResult.fromJson({
        'outcome': 'retry',
        'points': 0,
        'slice': 1,
        'spins_left': 0,
        'ad_spins_left': 2,
        'points_balance': 120,
      });
      final after =
          WheelStatus.fromJson(json(left: 1, adLeft: 2, adSpins: true))
              .after(r);

      expect(r.videoUnlocksSpin, isTrue);
      expect(after.videoUnlocksSpinAt(DateTime.now()), isTrue);
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

  group('après la vidéo', () {
    test('relit la roue jusqu\'à voir l\'essai débloqué', () async {
      final repo = _SequenceRepository([
        WheelStatus.fromJson(json(left: 0, adLeft: 2, adSpins: true)),
        WheelStatus.fromJson(json(left: 0, adLeft: 2, adSpins: true)),
        WheelStatus.fromJson(json(left: 1, adLeft: 1, adSpins: true)),
      ]);
      final container = ProviderContainer(overrides: [
        wheelRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      final sub = container.listen(wheelProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(wheelProvider.future);

      final unlocked = await container
          .read(wheelProvider.notifier)
          .waitForUnlockedSpin(every: Duration.zero);

      expect(unlocked, isTrue);
      expect(container.read(wheelProvider).value!.spinsLeft, 1);
      expect(repo.fetches, 3);
    });

    test('abandonne au bout du délai si le rappel n\'arrive pas', () async {
      final repo = _SequenceRepository([
        WheelStatus.fromJson(json(left: 0, adLeft: 2, adSpins: true)),
      ]);
      final container = ProviderContainer(overrides: [
        wheelRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
      final sub = container.listen(wheelProvider, (_, __) {});
      addTearDown(sub.close);
      await container.read(wheelProvider.future);

      final unlocked = await container
          .read(wheelProvider.notifier)
          .waitForUnlockedSpin(
            every: const Duration(milliseconds: 5),
            upTo: const Duration(milliseconds: 40),
          );

      expect(unlocked, isFalse);
      expect(container.read(wheelProvider).value!.spinsLeft, 0);
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

    testWidgets('plus d\'essai gratuit : une vidéo en propose un autre',
        (tester) async {
      final status =
          WheelStatus.fromJson(json(left: 0, adLeft: 2, adSpins: true));
      await pump(tester, const WheelScreen(),
          wheel: () => _FakeWheel(status, null));

      const c = WheelCopyFr();
      expect(find.text('Tourner la roue'), findsNothing);
      expect(find.text('Reviens demain'), findsNothing);
      expect(find.text(c.watchVideo), findsOneWidget);
      expect(find.text(c.videoSpinsLeft(2)), findsOneWidget);
      expect(find.text(c.subtitleWithVideo(1)), findsOneWidget);
    });

    testWidgets('AD_REQUIRED : on dit de regarder une vidéo', (tester) async {
      final status = WheelStatus.fromJson(json(left: 1));
      await pump(tester, const WheelScreen(),
          wheel: () => _FakeWheel(status, null,
              failure: ApiException(message: 'non', code: 'AD_REQUIRED')));

      await spinToTheEnd(tester, frames: 60);

      expect(find.text(const WheelCopyFr().adRequired), findsOneWidget);
    });

    testWidgets('le résultat propose la vidéo quand c\'est la seule suite',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: WheelResultDialog(
            result: SpinResult(
              outcome: WheelOutcome.retry,
              points: 0,
              slice: 1,
              spinsLeft: 0,
              adSpinsLeft: 1,
              pointsBalance: 120,
            ),
            copy: WheelCopyFr(),
            arabic: false,
          ),
        ),
      ));

      const c = WheelCopyFr();
      expect(find.text(c.retryBodyVideo), findsOneWidget);
      expect(find.text(c.watchVideoShort), findsOneWidget);
      expect(find.text(c.again), findsNothing);
    });

    testWidgets('la carte d\'entrée annonce l\'essai en vidéo',
        (tester) async {
      final status =
          WheelStatus.fromJson(json(left: 0, adLeft: 1, adSpins: true));
      await pump(tester, const Scaffold(body: WheelEntryCard()),
          wheel: () => _FakeWheel(status, null));

      expect(find.text(const WheelCopyFr().entryVideoSpin), findsOneWidget);
      expect(find.text('Jouer'), findsOneWidget);
    });

    testWidgets('les chances ne sont pas montrées aux membres', (tester) async {
      final status = WheelStatus.fromJson(json());
      await pump(tester, const WheelScreen(),
          wheel: () => _FakeWheel(status, null));

      expect(find.text('Règles'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
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

    // Le libellé long d'avant (« Regarder une vidéo pour un nouvel essai »)
    // rétrécissait jusqu'à toucher les bords arrondis du bouton. Les tests
    // dessinent avec une police de carrés, qui ne dit rien de la vraie
    // largeur : on tient donc la longueur du texte et la marge du bouton.
    test('le bouton vidéo garde un libellé court', () {
      for (final locale in AppLocale.values) {
        expect(AppStrings(locale).wheel.watchVideo.length, lessThanOrEqualTo(20));
      }
    });

    testWidgets('l\'icône du bouton vidéo reste loin du bord arrondi',
        (tester) async {
      final status =
          WheelStatus.fromJson(json(left: 0, adLeft: 2, adSpins: true));
      await pump(tester, const WheelScreen(),
          wheel: () => _FakeWheel(status, null));

      final label = find.text(const WheelCopyFr().watchVideo);
      final button =
          find.ancestor(of: label, matching: find.byType(InkWell)).first;
      final icon =
          find.descendant(of: button, matching: find.byType(Icon)).first;
      expect(tester.getTopLeft(icon).dx - tester.getTopLeft(button).dx,
          greaterThanOrEqualTo(20));
      expect(tester.getTopRight(button).dx - tester.getTopRight(label).dx,
          greaterThanOrEqualTo(20));
    });

    testWidgets('Récompenses : la roue en haut, même sans cadeau',
        (tester) async {
      final status = WheelStatus.fromJson(json(left: 2));
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          stringsProvider.overrideWithValue(const AppStrings(AppLocale.fr)),
          wheelProvider.overrideWith(() => _FakeWheel(status, null)),
          rewardsListProvider.overrideWith((ref) async => const []),
          appConfigJsonProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: RewardsScreen()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Roue de la chance'), findsOneWidget);
      expect(find.text('Jouer'), findsOneWidget);
      expect(
          find.text(const AppStrings(AppLocale.fr).noRewardsYet), findsOneWidget);
      expect(
          tester.getTopLeft(find.text('Roue de la chance')).dy,
          lessThan(tester
              .getTopLeft(
                  find.text(const AppStrings(AppLocale.fr).noRewardsYet))
              .dy));
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
        c.winTitle(10),
        c.retryBody(0),
        c.jackpotBody,
        c.noSpinsLeft,
        c.subtitleWithVideo(1),
        c.videoSpinsLeft(2),
        c.watchVideo,
        c.watchVideoShort,
        c.retryBodyVideo,
        c.unlockSlow,
        c.adRequired,
        c.entryVideoSpin,
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

class _SequenceRepository implements WheelRepository {
  _SequenceRepository(this.answers);

  /// Les réponses successives ; la dernière se répète.
  final List<WheelStatus> answers;
  int fetches = 0;

  @override
  Future<WheelStatus> fetch() async {
    final i = fetches < answers.length ? fetches : answers.length - 1;
    fetches++;
    return answers[i];
  }

  @override
  Future<SpinResult> spin() => throw UnimplementedError();
}
