import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/app_lock/data/app_lock_controller.dart';
import 'package:aji_tfarraj/features/app_lock/presentation/lock_screen.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart';

/// Face ID sans téléphone : chaque demande attend qu'on lui réponde.
class _FakeBiometrics extends BiometricService {
  final requests = <Completer<bool>>[];

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate(String reason) {
    final c = Completer<bool>();
    requests.add(c);
    return c.future;
  }
}

void main() {
  late _FakeBiometrics bio;

  Future<void> open(WidgetTester tester,
      {AppLocale locale = AppLocale.fr}) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    bio = _FakeBiometrics();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        stringsProvider.overrideWithValue(AppStrings(locale)),
        biometricServiceProvider.overrideWithValue(bio),
      ],
      child: const MaterialApp(home: LockScreen()),
    ));
    await tester.pump();
  }

  double buttonOpacity(WidgetTester tester, String label) => tester
      .widget<AnimatedOpacity>(find.ancestor(
          of: find.text(label), matching: find.byType(AnimatedOpacity)))
      .opacity;

  testWidgets('Face ID est demandé tout seul, sans bouton pendant la demande',
      (tester) async {
    await open(tester);
    final s = AppStrings(AppLocale.fr);

    expect(bio.requests, hasLength(1));
    expect(buttonOpacity(tester, s.biometricUnlockButton), 0);
    // Plus d'écran « Application verrouillée » : le logo, et c'est tout.
    expect(find.text(s.biometricUnlockTitle), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
        find.byWidgetPredicate(
            (w) => w is Image && w.image == LockScreen.cover),
        findsOneWidget);
  });

  testWidgets('annulé : un seul bouton, qui redemande Face ID', (tester) async {
    await open(tester);
    final s = AppStrings(AppLocale.fr);

    bio.requests.single.complete(false);
    await tester.pumpAndSettle();
    expect(buttonOpacity(tester, s.biometricUnlockButton), 1);

    await tester.tap(find.text(s.biometricUnlockButton));
    await tester.pump();
    expect(bio.requests, hasLength(2));
    expect(buttonOpacity(tester, s.biometricUnlockButton), 0);
  });

  for (final locale in AppLocale.values) {
    testWidgets('se dessine sans débordement (${locale.name})', (tester) async {
      await open(tester, locale: locale);
      bio.requests.single.complete(false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
