import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/app/copywriting/campaigns_copy.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/campaigns/data/campaigns_controller.dart';
import 'package:aji_tfarraj/features/campaigns/data/campaigns_repository.dart';
import 'package:aji_tfarraj/features/campaigns/domain/campaign.dart';
import 'package:aji_tfarraj/features/campaigns/presentation/campaign_actions.dart';
import 'package:aji_tfarraj/features/campaigns/presentation/campaign_banners.dart';
import 'package:aji_tfarraj/features/campaigns/presentation/campaign_popup.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart';
import 'package:aji_tfarraj/features/shows/domain/episode.dart';

/// La réponse d'exemple de docs/app-campaigns.md (backend).
const _popup = {
  'id': 3,
  'placement': 'popup',
  'image_url': 'https://app.ajitfarraj.ma/media/campaigns/tri9.jpg',
  'title': {'fr': 'Casting Tri9 Attahadi', 'ar': 'كاستينغ طريق التحدي'},
  'body': {'fr': null, 'ar': null},
  'cta': {'fr': "Je m'inscris", 'ar': 'سجل دابا'},
  'action': {
    'type': 'url',
    'url': 'https://app.ajitfarraj.ma/tri9?src=app_popup'
  },
  'can_hide_forever': true,
};

Map<String, dynamic> _banner(int id) => {
      ..._popup,
      'id': id,
      'placement': 'banner',
      'image_url': 'https://app.ajitfarraj.ma/media/campaigns/b$id.jpg',
    };

/// Le serveur, en mémoire : ce qu'il renvoie, et les événements reçus.
class _FakeRepo implements CampaignsRepository {
  CampaignFeed next = CampaignFeed.fromJson({
    'popup': _popup,
    'banners': [_banner(7), _banner(8)],
  });
  int fetches = 0;
  final events = <String>[];

  @override
  Future<CampaignFeed> fetch() async {
    fetches++;
    return next;
  }

  @override
  Future<void> event(Campaign c, String event) async =>
      events.add('${c.id}:${c.placement}:$event');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<(ProviderContainer, _FakeRepo)> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = _FakeRepo();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    campaignsRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(c.dispose);
  return (c, repo);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
    await initializeDateFormatting('ar');
  });

  group('la réponse', () {
    test('se lit comme dans la fiche du backend', () {
      final feed = CampaignFeed.fromJson({
        'popup': _popup,
        'banners': [_banner(7)],
      });
      final p = feed.popup!;
      expect(p.id, 3);
      expect(p.action.type, 'url');
      expect(p.action.url, contains('/tri9'));
      expect(p.canHideForever, isTrue);
      expect(feed.banners.single.placement, 'banner');
    });

    test('rien à montrer, 5 bannières au plus, une entrée sans image ignorée',
        () {
      expect(CampaignFeed.fromJson(const {'popup': null, 'banners': []}).popup,
          isNull);
      final feed = CampaignFeed.fromJson({
        'popup': {'id': 1, 'image_url': ''},
        'banners': [for (var i = 1; i <= 7; i++) _banner(i)],
      });
      expect(feed.popup, isNull);
      expect(feed.banners.length, 5);
      expect(CampaignFeed.fromJson(const {}).banners, isEmpty);
    });

    test('un épisode et un écran', () {
      final ep = CampaignAction.fromJson(
          const {'type': 'episode', 'show_id': 4, 'episode_id': 12});
      expect((ep.showId, ep.episodeId), (4, 12));
      expect(
          CampaignAction.fromJson(const {'type': 'screen', 'screen': 'rewards'})
              .screen,
          'rewards');
      expect(CampaignAction.fromJson(null).type, 'none');
    });

    test('les textes : la langue de l\'app, sinon l\'autre, sinon rien', () {
      const t = CampaignText(fr: 'Bonjour', ar: null);
      expect(t.pick(arabic: false), 'Bonjour');
      expect(t.pick(arabic: true), 'Bonjour');
      expect(const CampaignText(fr: ' ', ar: '').pick(arabic: false), isNull);
      expect(const CampaignText(fr: 'A', ar: 'ب').pick(arabic: true), 'ب');
    });
  });

  group('ce que l\'app envoie', () {
    test('un identifiant d\'installation stable, au format du serveur',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final id = installId(prefs);
      expect(id, matches(RegExp(r'^[A-Za-z0-9\-_.:]{8,64}$')));
      expect(installId(prefs), id);
    });

    test('une build de debug se présente en 99.0.0 (campagnes de test)', () {
      expect(campaignAppVersion('1.1.29'), '99.0.0');
    });

    test('la plateforme', () {
      expect(campaignPlatform(), anyOf('ios', 'android'));
    });
  });

  group('les écrans', () {
    test('chaque nom du serveur a son écran, un inconnu ramène à l\'accueil',
        () {
      expect(campaignScreenRoute('shows'), (route: Routes.browse, tab: true));
      expect(
          campaignScreenRoute('my_reservations').route, Routes.myReservations);
      expect(campaignScreenRoute('profile').route, Routes.profile);
      expect(campaignScreenRoute('profile_photo').route, Routes.editProfile);
      expect(campaignScreenRoute('rewards').route, Routes.rewards);
      expect(campaignScreenRoute('referral').route, Routes.referralStats);
      expect(campaignScreenRoute('lucky_wheel').route, Routes.wheel);
      expect(campaignScreenRoute('casting_profile').route, Routes.casting);
      expect(campaignScreenRoute('home').route, Routes.home);
      expect(campaignScreenRoute('nimporte_quoi').route, Routes.home);
      expect(campaignScreenRoute(null).route, Routes.home);
    });
  });

  group('l\'état', () {
    test('une fenêtre, une impression, puis plus d\'autre pendant ce lancement',
        () async {
      final (c, repo) = await _container();
      final n = c.read(campaignsProvider.notifier);

      await n.refresh();
      final popup = c.read(campaignsProvider).activePopup!;
      n.popupShown(popup);
      n.popupShown(popup);
      expect(repo.events, ['3:popup:impression']);

      n.closePopup(popup, never: true);
      expect(repo.events.last, '3:popup:never');
      expect(c.read(campaignsProvider).activePopup, isNull);

      // Une nouvelle fenêtre arrive : pas pendant ce lancement.
      await n.refresh();
      expect(c.read(campaignsProvider).activePopup, isNull);
    });

    test('le toucher envoie click et ferme la fenêtre', () async {
      final (c, repo) = await _container();
      final n = c.read(campaignsProvider.notifier);
      await n.refresh();
      n.tapped(c.read(campaignsProvider).activePopup!);
      expect(repo.events, ['3:popup:click']);
      expect(c.read(campaignsProvider).activePopup, isNull);
    });

    test('le retour au premier plan recharge après 30 minutes seulement',
        () async {
      final (c, repo) = await _container();
      final n = c.read(campaignsProvider.notifier);
      var now = DateTime(2026, 12, 1, 10);
      n.clock = () => now;

      await n.refreshIfStale();
      expect(repo.fetches, 1);
      now = now.add(const Duration(minutes: 20));
      await n.refreshIfStale();
      expect(repo.fetches, 1);
      now = now.add(const Duration(minutes: 11));
      await n.refreshIfStale();
      expect(repo.fetches, 2);
    });

    test(
        'une bannière fermée revient le lendemain, une impression par chargement',
        () async {
      final (c, repo) = await _container();
      final n = c.read(campaignsProvider.notifier);
      var now = DateTime(2026, 12, 1, 10);
      n.clock = () => now;

      await n.refresh();
      final b = c.read(campaignsProvider).banners.first;
      n.bannerShown(b);
      n.bannerShown(b);
      n.dismissBanner(b);
      expect(repo.events, ['7:banner:impression', '7:banner:dismiss']);
      expect(c.read(campaignsProvider).banners.map((x) => x.id), [8]);

      await n.refresh(); // le même jour : toujours cachée
      expect(c.read(campaignsProvider).banners.map((x) => x.id), [8]);

      now = now.add(const Duration(days: 1));
      await n.refresh();
      expect(c.read(campaignsProvider).banners.map((x) => x.id), [7, 8]);
    });

    test('une erreur réseau ne casse rien', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        campaignsRepositoryProvider.overrideWithValue(_FailingRepo()),
      ]);
      addTearDown(c.dispose);
      await c.read(campaignsProvider.notifier).refresh();
      expect(c.read(campaignsProvider).activePopup, isNull);
      expect(c.read(campaignsProvider).banners, isEmpty);
    });
  });

  group('l\'action', () {
    test(
        'un lien s\'ouvre dans le navigateur ; none et l\'inconnu ne font rien',
        () async {
      final opened = <String>[];
      Future<bool> open(String u) async {
        opened.add(u);
        return true;
      }

      // Pas de navigation pour ces trois-là : le routeur n'est pas touché.
      await runCampaignAction(_NoRouter(),
          const CampaignAction(type: 'url', url: 'https://x.ma/tri9'),
          openUrl: open);
      await runCampaignAction(_NoRouter(), CampaignAction.none, openUrl: open);
      await runCampaignAction(
          _NoRouter(), const CampaignAction(type: 'hologram'),
          openUrl: open);
      expect(opened, ['https://x.ma/tri9']);
    });

    test('« store » ouvre la fiche du store', () async {
      var store = 0;
      await runCampaignAction(
          _NoRouter(), const CampaignAction(type: 'screen', screen: 'store'),
          openStore: () async => store++);
      expect(store, 1);
    });

    test('seuls les liens web s\'ouvrent', () async {
      expect(await openCampaignUrl('javascript:alert(1)'), isFalse);
      expect(await openCampaignUrl('pas une url'), isFalse);
    });
  });

  group('l\'affichage', () {
    Future<_FakeRepo> pump(WidgetTester tester, AppLocale locale, Widget child,
        {bool loaded = true}) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = _FakeRepo();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          stringsProvider.overrideWithValue(AppStrings(locale)),
          campaignsRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Directionality(
            textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(body: child),
          ),
        ),
      ));
      return repo;
    }

    for (final locale in AppLocale.values) {
      testWidgets('la fenêtre tient à 375 px (${locale.name})', (tester) async {
        final feed = CampaignFeed.fromJson({'popup': _popup});
        final repo = await pump(tester, locale,
            Stack(children: [CampaignPopupOverlay(campaign: feed.popup!)]));
        await tester.pump();

        final c = AppStrings(locale).campaigns;
        expect(tester.takeException(), isNull);
        expect(find.text(c.neverShowAgain), findsOneWidget);
        expect(repo.events, ['3:popup:impression']);

        await tester.tap(find.bySemanticsLabel(c.close));
        await tester.pump();
        expect(repo.events.last, '3:popup:dismiss');
      });
    }

    testWidgets('sans « ne plus afficher » quand le serveur ne le permet pas',
        (tester) async {
      final feed = CampaignFeed.fromJson({
        'popup': {
          ..._popup,
          'can_hide_forever': false,
          'cta': {'fr': null, 'ar': null}
        },
      });
      await pump(tester, AppLocale.fr,
          Stack(children: [CampaignPopupOverlay(campaign: feed.popup!)]));
      await tester.pump();
      expect(find.text(const CampaignsCopyFr().neverShowAgain), findsNothing);
      // Sans texte de bouton : « Voir ».
      expect(find.text('Voir'), findsOneWidget);
    });

    testWidgets('les bannières : un carrousel, et le ✕ en cache une',
        (tester) async {
      late WidgetRef ref;
      final repo =
          await pump(tester, AppLocale.fr, Consumer(builder: (context, r, _) {
        ref = r;
        return const CampaignBanners();
      }));
      await ref.read(campaignsProvider.notifier).refresh();
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(PageView), findsOneWidget);
      expect(repo.events, ['7:banner:impression']);

      await tester.tap(find.bySemanticsLabel('Fermer').first);
      await tester.pump();
      expect(ref.read(campaignsProvider).banners.map((b) => b.id), [8]);
    });
  });

  group('les heures d\'un épisode', () {
    Episode ep(String start, String? end) => Episode.fromJson({
          'id': 1,
          'title': 'Prime',
          'starts_at': start,
          'ends_at': end,
          'city': 'Casablanca',
          'capacity': 100,
          'reserved_seats': 0,
          'date_fr': 'samedi 28 novembre 2026 à 20:00',
          'date_ar': 'السبت 28 نونبر 2026',
        });

    String strip(String s) => s.replaceAll(RegExp('[⁦⁩]'), '');

    test('début et fin, à l\'heure du téléphone', () {
      final e = ep('2026-11-28T20:00:00', '2026-11-28T23:00:00');
      expect(strip(e.hoursLabel!), '20:00 – 23:00');
      expect(e.endTimeLabel, '23:00');
      // La date seule, sans « à 20:00 » : l'heure a sa ligne.
      expect(e.dateOnlyLabel(false), 'samedi 28 novembre 2026');
      expect(e.dateOnlyLabel(true), 'السبت 28 نونبر 2026');
    });

    test('sans fin, ou une fin avant le début : le début seul', () {
      expect(strip(ep('2026-11-28T20:00:00', null).hoursLabel!), '20:00');
      expect(
          strip(ep('2026-11-28T20:00:00', '2026-11-28T19:00:00').hoursLabel!),
          '20:00');
      expect(ep('2026-11-28T20:00:00', null).endTimeLabel, isNull);
    });
  });
}

class _FailingRepo implements CampaignsRepository {
  @override
  Future<CampaignFeed> fetch() async => throw Exception('hors ligne');
  @override
  Future<void> event(Campaign c, String event) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Un routeur qui échoue s'il est touché : ces actions ne naviguent pas.
class _NoRouter implements GoRouter {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('router used: ${invocation.memberName}');
}
