// Les trois clips de l'espace chargé public : partager, suivre ses invités,
// lire ses gains.
//
// Ce qui doit tenir : un membre ordinaire ne se les voit jamais proposer — ils
// parlent de pages qu'il ne peut pas ouvrir —, et le bandeau de bienvenue les
// annonce tous les trois d'un coup, puis ne revient plus.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;
import 'package:aji_tfarraj/features/tutorials/data/tutorials_repository.dart';
import 'package:aji_tfarraj/features/tutorials/domain/tutorial.dart';
import 'package:aji_tfarraj/features/tutorials/presentation/tutorial_widgets.dart';

Map<String, dynamic> _clip(String name, int duration) => {
      'video_url': 'https://api.test/tutorials/$name.mp4',
      'poster_url': 'https://api.test/tutorials/$name.jpg',
      'duration': duration,
    };

final _tutorials = Tutorials.fromAppConfig({
  'tutorials': {
    'profile': {'fr': _clip('tuto_profil_fr', 49)},
    'cp_share': {'fr': _clip('cp_share_fr', 30), 'ar': _clip('cp_share_ar', 30)},
    'cp_guests': {'fr': _clip('cp_guests_fr', 38)},
    'cp_earnings': {'fr': _clip('cp_earnings_fr', 53)},
  },
});

void main() {
  const s = AppStrings(AppLocale.fr);

  group('ce que le serveur annonce', () {
    test('les trois clips de l\'espace arrivent, dans la bonne langue', () {
      expect(
        _tutorials.clipFor(TutorialTopic.cpShare, AppLocale.ar)!.video.path,
        endsWith('cp_share_ar.mp4'),
      );
      expect(
        _tutorials.clipFor(TutorialTopic.cpEarnings, AppLocale.fr)!.duration,
        const Duration(seconds: 53),
      );
    });

    test('un clip qui manque dans sa langue retombe sur l\'autre', () {
      expect(
        _tutorials.clipFor(TutorialTopic.cpGuests, AppLocale.ar)!.video.path,
        endsWith('cp_guests_fr.mp4'),
        reason: 'les écrans sont les mêmes : un clip aide plus que rien',
      );
    });
  });

  group('à qui on les propose', () {
    test('un membre ordinaire ne voit aucun clip de l\'espace', () {
      final offered = TutorialTopic.offeredTo(chargePublic: false);

      expect(offered, contains(TutorialTopic.profile));
      expect(
        offered.where((t) => t.isChargePublic),
        isEmpty,
        reason: 'ces clips montrent des pages qu\'il ne peut pas ouvrir',
      );
    });

    /// Les points et les récompenses concernent tout le monde : la vidéo ne
    /// doit pas être prise pour un clip de l'espace chargé public.
    test('la vidéo des récompenses est proposée à tous les membres', () {
      expect(TutorialTopic.rewards.isChargePublic, isFalse);
      expect(TutorialTopic.offeredTo(chargePublic: false),
          contains(TutorialTopic.rewards));

      final tutorials = Tutorials.fromAppConfig({
        'tutorials': {
          'rewards': {'ar': _clip('rewards_ar', 103)},
        },
      });
      expect(tutorials.clipFor(TutorialTopic.rewards, AppLocale.ar)!.duration,
          const Duration(seconds: 103));
    });

    test('un chargé public les voit tous', () {
      expect(
        TutorialTopic.offeredTo(chargePublic: true),
        containsAll(TutorialTopic.chargePublic),
      );
      expect(TutorialTopic.chargePublic, hasLength(3));
    });
  });

  group('le bandeau de bienvenue', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          // Un conteneur neuf à chaque fois, comme après un redémarrage.
          key: UniqueKey(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tutorialsProvider.overrideWith((ref) async => _tutorials),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TutorialOfferBanner(
                topic: TutorialTopic.cpShare,
                also: const [TutorialTopic.cpGuests, TutorialTopic.cpEarnings],
                message: s.tutorialCpFirstTime,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('un seul bandeau annonce les trois vidéos', (tester) async {
      await pump(tester);

      expect(find.text(s.tutorialCpFirstTime), findsOneWidget);
      expect(find.byType(TutorialOfferBanner), findsOneWidget);
    });

    testWidgets('le masquer retire les trois, pas seulement le premier',
        (tester) async {
      await pump(tester);

      await tester.tap(find.byTooltip(s.tutorialDismiss));
      await tester.pumpAndSettle();

      expect(find.text(s.tutorialCpFirstTime), findsNothing);

      // Et au redémarrage, aucun des trois ne revient réclamer l'écran.
      await pump(tester);
      expect(find.text(s.tutorialCpFirstTime), findsNothing);
      for (final topic in TutorialTopic.chargePublic) {
        expect(prefs.getBool('tutorial_offer_done_${topic.key}'), isTrue);
      }
    });
  });
}
