// La publicité : ce que le serveur autorise, et quand une pub a le droit de
// s'ouvrir.
//
// Ce qui doit tenir : rien tant que le serveur ne l'allume pas ; un
// emplacement sans unité reste fermé ; deux réservations rapprochées ne
// donnent qu'une pub ; et l'écran fidélité ne propose la vidéo que s'il reste
// quelque chose à gagner aujourd'hui.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/ads/data/ads_gateway.dart';
import 'package:aji_tfarraj/features/ads/data/ads_service.dart';
import 'package:aji_tfarraj/features/ads/domain/ads_config.dart';
import 'package:aji_tfarraj/features/loyalty/domain/points_summary.dart';
import 'package:aji_tfarraj/features/loyalty/presentation/widgets/watch_for_points_card.dart';

/// Une porte qui ne montre rien mais retient ce qu'on lui a demandé.
class _FakeGateway implements AdsGateway {
  _FakeGateway({this.interstitialShown = true, this.rewardEarned = true});

  final bool interstitialShown;
  final bool rewardEarned;

  int interstitialCalls = 0;
  int preloadCalls = 0;
  int rewardedCalls = 0;
  String? lastUserId;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> preloadInterstitial(String unitId) async {
    preloadCalls++;
  }

  @override
  Future<bool> showInterstitial(String unitId,
      {Duration wait = const Duration(seconds: 4)}) async {
    interstitialCalls++;
    return interstitialShown;
  }

  @override
  Future<bool> showRewarded(String unitId, {required String userId}) async {
    rewardedCalls++;
    lastUserId = userId;
    return rewardEarned;
  }
}

Map<String, dynamic> _serverSays({
  bool enabled = true,
  String? interstitial = 'unit/interstitial',
  String? rewarded = 'unit/rewarded',
  int cooldownMinutes = 30,
}) =>
    {
      'ads': {
        'enabled': enabled,
        'interstitial_unit_id': interstitial,
        'rewarded_unit_id': rewarded,
        'reservation': {
          'enabled': true,
          'cooldown_minutes': cooldownMinutes,
        },
        'rewarded': {'enabled': true, 'points': 5, 'daily_cap': 3},
      },
    };

void main() {
  const s = AppStrings(AppLocale.fr);

  group('ce que le serveur autorise', () {
    test('rien tant qu\'il ne l\'allume pas', () {
      for (final json in <Object?>[
        null,
        <String, dynamic>{},
        {'ads': <dynamic>[]},
        _serverSays(enabled: false),
      ]) {
        final config = AdsConfig.fromAppConfig(json);

        expect(config.isOff, isTrue, reason: '$json');
        expect(config.reservation.enabled, isFalse);
        expect(config.rewarded.enabled, isFalse);
      }
    });

    test('allumé, chaque emplacement arrive avec ses réglages', () {
      final config = AdsConfig.fromAppConfig(_serverSays());

      expect(config.interstitialUnitId, 'unit/interstitial');
      expect(config.reservation.cooldown, const Duration(minutes: 30));
      expect(config.rewarded.points, 5);
      expect(config.rewarded.dailyCap, 3);
    });

    test('un emplacement sans unité reste fermé', () {
      final config = AdsConfig.fromAppConfig(_serverSays(interstitial: '  '));

      expect(config.reservation.enabled, isFalse,
          reason: 'sans unité, l\'écran attendrait une pub qui ne vient pas');
      expect(config.rewarded.enabled, isTrue, reason: 'l\'autre reste ouvert');
    });
  });

  group('la pub d\'après-réservation', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    AdsService service(_FakeGateway gateway,
            {Object? json, DateTime Function()? clock}) =>
        AdsService(
          gateway: gateway,
          config: AdsConfig.fromAppConfig(json ?? _serverSays()),
          prefs: prefs,
          clock: clock ?? DateTime.now,
        );

    test('s\'ouvre une fois la place enregistrée', () async {
      final gateway = _FakeGateway();

      expect(await service(gateway).showAfterReservation(), isTrue);
      expect(gateway.interstitialCalls, 1);
    });

    /// Préchargée pendant que la personne remplit sa réservation : au moment
    /// de l'afficher elle est déjà là, sinon la confirmation attendrait
    /// derrière un écran vide.
    test('elle se prépare pendant que la personne réserve', () async {
      final gateway = _FakeGateway();

      await service(gateway).prepareForReservation();
      expect(gateway.preloadCalls, 1);
    });

    test('rien ne se précharge pendant le délai entre deux pubs', () async {
      final gateway = _FakeGateway();
      var now = DateTime(2026, 9, 22, 20, 0);
      final ads = service(gateway, clock: () => now);

      await ads.showAfterReservation();
      now = now.add(const Duration(minutes: 5));
      await ads.prepareForReservation();

      expect(gateway.preloadCalls, 0,
          reason: 'charger une pub qu\'on ne montrera pas coûte des données');
    });

    test('éteinte côté serveur, elle ne précharge rien non plus', () async {
      final gateway = _FakeGateway();

      await service(gateway, json: _serverSays(enabled: false))
          .prepareForReservation();
      expect(gateway.preloadCalls, 0);
    });

    test('deux réservations rapprochées ne donnent qu\'une pub', () async {
      final gateway = _FakeGateway();
      var now = DateTime(2026, 9, 22, 20, 0);
      final ads = service(gateway, clock: () => now);

      await ads.showAfterReservation();
      now = now.add(const Duration(minutes: 5));
      expect(await ads.showAfterReservation(), isFalse);
      expect(gateway.interstitialCalls, 1);

      // Passé le délai, la suivante repasse.
      now = now.add(const Duration(minutes: 30));
      expect(await ads.showAfterReservation(), isTrue);
      expect(gateway.interstitialCalls, 2);
    });

    /// Une pub qui n'a pas pu se charger ne doit pas consommer le créneau :
    /// sinon une panne de réseau éteint la publicité pour une demi-heure.
    test('un échec de chargement ne consomme pas le délai', () async {
      final gateway = _FakeGateway(interstitialShown: false);
      final ads = service(gateway);

      expect(await ads.showAfterReservation(), isFalse);
      expect(await ads.showAfterReservation(), isFalse);
      expect(gateway.interstitialCalls, 2);
      expect(prefs.getString('ads_last_interstitial_at'), isNull);
    });

    test('éteinte côté serveur, elle ne demande rien au réseau', () async {
      final gateway = _FakeGateway();
      final ads = service(gateway, json: _serverSays(enabled: false));

      expect(await ads.showAfterReservation(), isFalse);
      expect(gateway.interstitialCalls, 0);
    });
  });

  group('la vidéo récompensée', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('part avec l\'identifiant du membre, sinon personne n\'est crédité',
        () async {
      final gateway = _FakeGateway();
      final ads = AdsService(
        gateway: gateway,
        config: AdsConfig.fromAppConfig(_serverSays()),
        prefs: prefs,
      );

      expect(await ads.showRewarded(userId: 4212), isTrue);
      expect(gateway.lastUserId, '4212');
    });

    test('elle ne suit pas le délai de l\'interstitiel', () async {
      final gateway = _FakeGateway();
      final ads = AdsService(
        gateway: gateway,
        config: AdsConfig.fromAppConfig(_serverSays()),
        prefs: prefs,
      );

      await ads.showAfterReservation();
      expect(await ads.showRewarded(userId: 1), isTrue,
          reason: 'c\'est le membre qui la demande, pas l\'app qui l\'impose');
    });
  });

  group('ce que compte le serveur', () {
    AdRewardStatus status(Map<String, dynamic> json) =>
        PointsSummary.fromJson({'balance': 0, 'history': [], 'ad_reward': json})
            .adReward;

    test('le quota épuisé retire la proposition', () {
      expect(
        status({
          'enabled': true,
          'points': 5,
          'daily_cap': 3,
          'remaining_today': 0
        }).canWatch,
        isFalse,
      );
      expect(
        status({
          'enabled': true,
          'points': 5,
          'daily_cap': 3,
          'remaining_today': 2
        }).canWatch,
        isTrue,
      );
    });

    test('un serveur d\'avant la fonction ne propose rien', () {
      final summary = PointsSummary.fromJson({'balance': 40, 'history': []});

      expect(summary.balance, 40);
      expect(summary.adReward.canWatch, isFalse);
    });

    /// Le solde est gardé sur le disque entre deux lancements : ce qui est
    /// écrit doit se relire tel quel.
    test('le cache disque garde ce qu\'il reste pour aujourd\'hui', () {
      final summary = PointsSummary.fromJson({
        'balance': 40,
        'history': [],
        'ad_reward': {
          'enabled': true,
          'points': 5,
          'daily_cap': 3,
          'remaining_today': 1
        },
      });

      expect(PointsSummary.fromJson(summary.toJson()).adReward.remainingToday,
          1);
    });
  });

  group('la carte sur l\'écran fidélité', () {
    Future<void> pump(WidgetTester tester,
        {required AdRewardStatus status, bool busy = false}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WatchForPointsCard(
            status: status,
            strings: s,
            busy: busy,
            onWatch: () {},
          ),
        ),
      ));
    }

    testWidgets('elle annonce le gain et ce qu\'il reste', (tester) async {
      await pump(
        tester,
        status: const AdRewardStatus(
            enabled: true, points: 5, dailyCap: 3, remainingToday: 2),
      );

      expect(find.text(s.adRewardTitle), findsOneWidget);
      expect(find.text(s.adRewardPoints(5)), findsOneWidget);
      expect(find.text(s.adRewardRemaining(2)), findsOneWidget);
      expect(find.text(s.adRewardWatch), findsOneWidget);
    });

    testWidgets('pendant la vidéo, le bouton ne se retape pas',
        (tester) async {
      await pump(
        tester,
        status: const AdRewardStatus(
            enabled: true, points: 5, dailyCap: 3, remainingToday: 2),
        busy: true,
      );

      expect(find.text(s.adRewardWatch), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
