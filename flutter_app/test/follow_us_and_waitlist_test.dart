// Deux retours du 30/10 : nos réseaux sociaux dans le Profil, et la liste
// d'attente dite au client.
//
// Ce qui doit tenir : un lien douteux ou un réseau inconnu ne devient jamais
// un bouton ; sans lien, la carte n'existe pas ; et « Liste d'attente » ne
// s'affiche que sur une demande encore en attente.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aji_tfarraj/app/copywriting/follow_us_copy.dart';
import 'package:aji_tfarraj/app/copywriting/waitlist_copy.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';
import 'package:aji_tfarraj/features/reservations/presentation/waitlist_widgets.dart';
import 'package:aji_tfarraj/features/social/domain/social_link.dart';
import 'package:aji_tfarraj/features/social/presentation/follow_us_card.dart';

Reservation _reservation(String status, {String? waitlist}) =>
    Reservation.fromJson({
      'id': 1,
      'user_id': 1,
      'show_id': 1,
      'seats': 2,
      'status': status,
      'created_at': '2026-10-29T10:00:00Z',
      if (waitlist != null) 'waitlist': waitlist,
    });

void main() {
  group('nos réseaux', () {
    test('seuls les réseaux connus, en https, dans l\'ordre du serveur', () {
      final links = SocialLink.fromAppConfig({
        'social_links': [
          {'network': 'tiktok', 'url': 'https://www.tiktok.com/@ajitfarraj'},
          {'network': 'instagram', 'url': 'https://instagram.com/ajitfarraj'},
          {'network': 'instagram', 'url': 'https://instagram.com/doublon'},
          {'network': 'myspace', 'url': 'https://myspace.com/ajitfarraj'},
          {'network': 'facebook', 'url': 'http://facebook.com/ajitfarraj'},
          {'network': 'youtube', 'url': 'javascript:alert(1)'},
          'pas une carte',
        ],
      });

      expect(links.map((l) => l.network), ['tiktok', 'instagram']);
      expect(links[1].url.toString(), 'https://instagram.com/ajitfarraj');
    });

    test('un vieux serveur, ou pas de réponse : aucun lien', () {
      expect(SocialLink.fromAppConfig(null), isEmpty);
      expect(SocialLink.fromAppConfig({'tutorials': {}}), isEmpty);
    });

    Future<void> pumpCard(WidgetTester tester, List<SocialLink> links,
        {AppLocale locale = AppLocale.fr}) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          stringsProvider.overrideWithValue(AppStrings(locale)),
          socialLinksProvider.overrideWith((ref) async => links),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FollowUsCard(padding: EdgeInsets.all(16)),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('sans lien dans le tableau de bord, la carte n\'existe pas',
        (tester) async {
      await pumpCard(tester, const []);

      expect(find.text(const FollowUsCopyFr().title), findsNothing);
      expect(
          find.byWidgetPredicate((w) =>
              w is Padding && w.padding == const EdgeInsets.all(16)),
          findsNothing);
    });

    testWidgets('un bouton par réseau, nommé pour les lecteurs d\'écran',
        (tester) async {
      await pumpCard(tester, [
        SocialLink(
            network: 'instagram',
            url: Uri.parse('https://instagram.com/ajitfarraj')),
        SocialLink(
            network: 'tiktok',
            url: Uri.parse('https://www.tiktok.com/@ajitfarraj')),
      ]);

      expect(find.text('Suis Aji Tfarraj'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.bySemanticsLabel('Suivre Aji Tfarraj sur Instagram'),
          findsOneWidget);
    });
  });

  group('liste d\'attente', () {
    test('seulement sur une demande encore en attente', () {
      expect(_reservation('pending_review', waitlist: 'waiting').onWaitlist,
          isTrue);
      expect(
          _reservation('contacting', waitlist: 'coming').waitlistComing, isTrue);
      // Approuvée le jour J : c'est un billet, plus une attente.
      expect(_reservation('approved', waitlist: 'coming').onWaitlist, isFalse);
      // Un vieux serveur n'envoie rien.
      expect(_reservation('pending_review').onWaitlist, isFalse);
      // Une valeur inconnue (un jour « ready » fuirait) ne dit rien.
      expect(_reservation('pending_review', waitlist: 'ready').onWaitlist,
          isFalse);
    });

    for (final locale in AppLocale.values) {
      testWidgets('le badge et l\'explication (${locale.name})',
          (tester) async {
        final c = AppStrings(locale).waitlist;
        await tester.pumpWidget(ProviderScope(
          overrides: [stringsProvider.overrideWithValue(AppStrings(locale))],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  WaitlistBadge(
                      reservation:
                          _reservation('pending_review', waitlist: 'waiting')),
                  WaitlistNotice(
                      reservation:
                          _reservation('contacting', waitlist: 'coming')),
                ],
              ),
            ),
          ),
        ));

        expect(find.text(c.waitingBadge), findsOneWidget);
        expect(find.text(c.comingBody), findsOneWidget);
      });
    }

    test('le français et l\'arabe disent la même chose', () {
      for (final WaitlistCopy c in [
        const WaitlistCopyFr(),
        const WaitlistCopyAr()
      ]) {
        for (final text in [
          c.waitingBadge,
          c.comingBadge,
          c.waitingBody,
          c.comingBody,
        ]) {
          expect(text.trim(), isNotEmpty);
        }
      }
    });
  });
}
