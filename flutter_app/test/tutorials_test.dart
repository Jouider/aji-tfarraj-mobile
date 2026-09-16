import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;
import 'package:aji_tfarraj/features/tutorials/data/tutorials_repository.dart';
import 'package:aji_tfarraj/features/tutorials/domain/tutorial.dart';

/// The clips come from `GET /api/app-config → tutorials`. The app must read
/// them faithfully, pick the member's language, and treat anything it cannot
/// play as "no clip" — never as a button that plays nothing.
void main() {
  Map<String, dynamic> clip(String url, {Object? duration = 49}) => {
        'video_url': url,
        'poster_url': 'https://api.test/tutorials/poster.jpg',
        'duration': duration,
      };

  final config = {
    'latest_version': '1.1.11',
    'tutorials': {
      'profile': {
        'fr': clip('https://api.test/tutorials/tuto_profil_fr.mp4'),
        'ar': clip('https://api.test/tutorials/tuto_profil_ar.mp4', duration: 44),
      },
      'reservation_referral': {
        'fr': clip('https://api.test/tutorials/tuto_reservation_parrainage_fr.mp4',
            duration: 43),
      },
    },
  };

  group('reading the clips', () {
    test("each topic plays in the member's language", () {
      final tutorials = Tutorials.fromAppConfig(config);

      expect(tutorials.clipFor(TutorialTopic.profile, AppLocale.fr)!.video.path,
          endsWith('tuto_profil_fr.mp4'));
      expect(tutorials.clipFor(TutorialTopic.profile, AppLocale.ar)!.video.path,
          endsWith('tuto_profil_ar.mp4'));
      expect(
          tutorials.clipFor(TutorialTopic.profile, AppLocale.ar)!.duration,
          const Duration(seconds: 44));
    });

    /// The screens are the same in both languages: a clip helps more than none.
    test('with only one language, the other reader gets that clip', () {
      final tutorials = Tutorials.fromAppConfig(config);

      expect(
        tutorials
            .clipFor(TutorialTopic.reservationReferral, AppLocale.ar)!
            .video
            .path,
        endsWith('tuto_reservation_parrainage_fr.mp4'),
      );
    });

    test('an older server without clips means no clip anywhere', () {
      final tutorials = Tutorials.fromAppConfig({'latest_version': '1.1.11'});

      for (final topic in TutorialTopic.values) {
        expect(tutorials.clipFor(topic, AppLocale.fr), isNull);
      }
    });

    /// PHP encodes an empty array as `[]`.
    test('an empty list from the server is read as no clips', () {
      expect(
        Tutorials.fromAppConfig({'tutorials': <dynamic>[]})
            .clipFor(TutorialTopic.profile, AppLocale.fr),
        isNull,
      );
      expect(Tutorials.fromAppConfig(null).clipFor(TutorialTopic.profile, AppLocale.fr),
          isNull);
    });

    test('an entry that cannot be played is skipped, not shown', () {
      final tutorials = Tutorials.fromAppConfig({
        'tutorials': {
          'profile': {
            'fr': {'duration': 49}, // no URL
            'ar': clip('tutorials/tuto_profil_ar.mp4'), // relative
          },
          'reservation_referral': {
            'fr': clip('javascript:alert(1)'), // not a web address
            'ar': 'oops',
          },
          'unknown_topic': {'fr': clip('https://api.test/x.mp4')},
        },
      });

      expect(tutorials.clipFor(TutorialTopic.profile, AppLocale.fr), isNull);
      expect(tutorials.clipFor(TutorialTopic.reservationReferral, AppLocale.fr),
          isNull);
    });

    test('a missing or zero duration is simply not shown', () {
      final noDuration = Tutorials.fromAppConfig({
        'tutorials': {
          'profile': {'fr': clip('https://api.test/a.mp4', duration: null)},
          'reservation_referral': {'fr': clip('https://api.test/b.mp4', duration: 0)},
        },
      });

      expect(noDuration.clipFor(TutorialTopic.profile, AppLocale.fr)!.duration,
          isNull);
      expect(
          noDuration
              .clipFor(TutorialTopic.reservationReferral, AppLocale.fr)!
              .duration,
          isNull);
    });

    test('durations read like a clock', () {
      expect(formatClipDuration(const Duration(seconds: 49)), '0:49');
      expect(formatClipDuration(const Duration(seconds: 65)), '1:05');
      expect(formatClipDuration(null), '');
    });
  });

  group('the first-time banner', () {
    Future<ProviderContainer> containerWith(SharedPreferences prefs) async {
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test('is offered until hidden, then never again on this device', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final first = await containerWith(prefs);
      expect(first.read(tutorialOfferProvider(TutorialTopic.profile)), isTrue);

      first.read(tutorialOfferProvider(TutorialTopic.profile).notifier).dismiss();
      expect(first.read(tutorialOfferProvider(TutorialTopic.profile)), isFalse);

      final afterRestart = await containerWith(prefs);
      expect(afterRestart.read(tutorialOfferProvider(TutorialTopic.profile)),
          isFalse);
    });

    test('each topic has its own banner', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = await containerWith(prefs);

      container
          .read(tutorialOfferProvider(TutorialTopic.profile).notifier)
          .dismiss();

      expect(
          container.read(tutorialOfferProvider(TutorialTopic.reservationReferral)),
          isTrue);
    });
  });
}
