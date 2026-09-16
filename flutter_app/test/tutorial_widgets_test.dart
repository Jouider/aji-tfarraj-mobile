// The three ways a tutorial clip is offered, pumped with and without a clip
// from the server. A help button that plays nothing is worse than none, so
// every entry point must vanish when there is no clip.

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

final _withClips = Tutorials.fromAppConfig({
  'tutorials': {
    'profile': {
      'fr': {
        'video_url': 'https://api.test/tutorials/tuto_profil_fr.mp4',
        'duration': 49,
      },
    },
  },
});

Future<void> _pump(
  WidgetTester tester, {
  required Tutorials tutorials,
  required SharedPreferences prefs,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      // A fresh scope each time, as after an app restart.
      key: UniqueKey(),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tutorialsProvider.overrideWith((ref) async => tutorials),
      ],
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: const [TutorialHelpAction(topic: TutorialTopic.profile)],
          ),
          body: const Column(
            children: [
              TutorialOfferBanner(topic: TutorialTopic.profile),
              TutorialHowToLink(topic: TutorialTopic.profile),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump(); // let the clips resolve
  await tester.pump();
}

void main() {
  const s = AppStrings(AppLocale.fr);

  testWidgets('no clip from the server: no "?", no banner, no link',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pump(tester, tutorials: Tutorials.none, prefs: prefs);

    expect(find.byIcon(Icons.help_outline), findsNothing);
    expect(find.text(s.tutorialProfileOffer), findsNothing);
    expect(find.textContaining(s.tutorialHowTo), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with a clip: the "?", the banner and the timed link appear',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pump(tester, tutorials: _withClips, prefs: prefs);

    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.text(s.tutorialProfileOffer), findsOneWidget);
    expect(find.text('${s.tutorialWatch} · 0:49'), findsOneWidget);
    expect(find.text('${s.tutorialHowTo} · 0:49'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a hidden banner stays hidden after a restart, the "?" stays',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pump(tester, tutorials: _withClips, prefs: prefs);
    await tester.tap(find.byTooltip(s.tutorialDismiss));
    await tester.pump();
    expect(find.text(s.tutorialProfileOffer), findsNothing);

    await _pump(tester, tutorials: _withClips, prefs: prefs);
    expect(find.text(s.tutorialProfileOffer), findsNothing);
    expect(find.byIcon(Icons.help_outline), findsOneWidget,
        reason: 'the clip is still one tap away');
  });
}
