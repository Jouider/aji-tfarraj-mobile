// Smoke test: the root app widget builds and renders its MaterialApp shell.
//
// `main()` does real device setup (Firebase, FCM, deep links) before running
// the app. None of that is available in the test VM, so the smoke test mirrors
// the two things `main()` provides for the app to build:
//   1. an overridden `sharedPreferencesProvider` (read on startup), and
//   2. `AjiTfarrajApp(initializePushServices: false)` so the post-frame
//      Firebase/push wiring is skipped.
// What's left is the part worth smoke-testing: the app boots, resolves its
// theme/locale/router, and renders a MaterialApp without throwing.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/main.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build the app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const AjiTfarrajApp(initializePushServices: false),
      ),
    );
    await tester.pump();

    // The app built without errors and produced its MaterialApp shell.
    expect(find.byType(AjiTfarrajApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);

    // The splash screen schedules a delayed navigation (Future.delayed). Flush
    // it so no Timer is left pending when the test tears down. (Can't use
    // pumpAndSettle here — the splash's CircularProgressIndicator never settles.)
    await tester.pump(const Duration(seconds: 3));
  });
}
