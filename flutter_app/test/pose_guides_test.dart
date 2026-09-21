// La démonstration vidéo de chaque pose du book, montrée dans le guide avant
// que la caméra ne s'ouvre.
//
// Ce qui doit tenir : chaque pose trouve sa démonstration ; une clé que l'app
// ne connaît plus — le plein pied de dos, retiré — est ignorée sans rien
// casser ; et sans démonstration, le guide reste le texte qu'il était.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';
import 'package:aji_tfarraj/features/casting/domain/pose_guides.dart';
import 'package:aji_tfarraj/features/casting/presentation/pose_guide_sheet.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;

Map<String, dynamic> _clip(String name, int duration) => {
      'video_url': 'https://api.test/tutorials/$name.mp4',
      'poster_url': 'https://api.test/tutorials/$name.jpg',
      'duration': duration,
    };

final _config = {
  'pose_guides': {
    'full_front': _clip('pose_full_front', 10),
    'full_profile': _clip('pose_full_profile', 15),
    'portrait': _clip('pose_portrait', 17),
    'portrait_smile': _clip('pose_portrait_smile', 11),
    // Un ancien serveur pourrait encore l'annoncer.
    'full_back': _clip('pose_full_back', 12),
  },
};

void main() {
  const s = AppStrings(AppLocale.fr);

  group('ce que le serveur annonce', () {
    test('chaque pose trouve sa démonstration', () {
      final guides = PoseGuides.fromAppConfig(_config);

      for (final pose in CastingPose.values) {
        expect(guides.forPose(pose), isNotNull, reason: pose.key);
      }
      expect(guides.forPose(CastingPose.portrait)!.video.path,
          endsWith('pose_portrait.mp4'));
    });

    test('le plein pied de dos, retiré, est ignoré sans rien casser', () {
      expect(() => PoseGuides.fromAppConfig(_config), returnsNormally);
      expect(CastingPose.fromKey('full_back'), isNull);
    });

    test('un serveur sans démonstrations — ou qui envoie [] — n\'en donne aucune',
        () {
      for (final json in [
        null,
        <String, dynamic>{},
        {'pose_guides': <dynamic>[]},
      ]) {
        final guides = PoseGuides.fromAppConfig(json);
        expect(guides.forPose(CastingPose.fullFront), isNull);
      }
    });
  });

  group('le guide avant la caméra', () {
    Future<void> openGuide(WidgetTester tester, PoseGuides guides) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            poseGuidesProvider.overrideWith((ref) async => guides),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showPoseGuide(context, ref,
                        pose: CastingPose.fullFront),
                    child: const Text('ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      // Pas de pumpAndSettle : l'indicateur de chargement ne se pose jamais.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('la démonstration est là, avec sa légende', (tester) async {
      await openGuide(tester, PoseGuides.fromAppConfig(_config));

      expect(find.text(s.casting.poseDemoCaption), findsOneWidget);
      expect(find.text(s.casting.bookTake), findsOneWidget,
          reason: 'le bouton pour photographier reste là');
      expect(tester.takeException(), isNull);
    });

    testWidgets('sans démonstration, le guide reste le texte qu\'il était',
        (tester) async {
      await openGuide(tester, PoseGuides.none);

      expect(find.text(s.casting.poseDemoCaption), findsNothing);
      expect(find.text(s.casting.fullFront.label), findsOneWidget);
      expect(find.text(s.casting.bookTake), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
