import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart';
import 'package:aji_tfarraj/features/profile/profile_screen.dart';

/// Des membres touchaient « Supprimer mon compte » au lieu de « Se
/// déconnecter ». La suppression demande maintenant d'écrire le mot.
void main() {
  Future<List<bool?>> open(WidgetTester tester, AppLocale locale) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final results = <bool?>[];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        stringsProvider.overrideWithValue(AppStrings(locale)),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  results.add(await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const DeleteAccountSheet(),
              )),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  FilledButton confirm(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('le bouton rouge reste éteint tant que le mot n\'est pas écrit',
      (tester) async {
    final results = await open(tester, AppLocale.fr);
    final c = AppStrings(AppLocale.fr).accountDeletion;

    expect(confirm(tester).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'SUPPR');
    await tester.pump();
    expect(confirm(tester).onPressed, isNull);

    // En minuscules aussi : le clavier n'est pas toujours en majuscules.
    await tester.enterText(find.byType(TextField), 'supprimer');
    await tester.pump();
    expect(confirm(tester).onPressed, isNotNull);

    await tester.tap(find.text(c.confirm));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  testWidgets('Annuler ne supprime rien', (tester) async {
    final results = await open(tester, AppLocale.fr);

    await tester
        .tap(find.text(AppStrings(AppLocale.fr).accountDeletion.cancel));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });

  testWidgets('en arabe, le mot est « حذف »', (tester) async {
    await open(tester, AppLocale.ar);

    await tester.enterText(find.byType(TextField), 'حذف');
    await tester.pump();
    expect(confirm(tester).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
