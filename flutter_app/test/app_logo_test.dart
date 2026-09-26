import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/primitives/app_logo.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';

/// Un chemin d'asset faux ne casse ni la compilation ni les tests : il donne
/// un carré gris, sur l'écran de lancement, chez l'utilisateur. Ces tests
/// vérifient donc que chaque variante que [AppLogo] sait demander existe
/// vraiment sur le disque — et qu'elle est bien déclarée au bundle.
void main() {
  final declared = File('pubspec.yaml').readAsStringSync();

  group('les fichiers du logo', () {
    test('les cinq variantes existent', () {
      final expected = [
        'mark.png',
        'lockup_fr_on_dark.png',
        'lockup_fr_on_light.png',
        'lockup_ar_on_dark.png',
        'lockup_ar_on_light.png',
      ];

      for (final name in expected) {
        final path = 'assets/images/ajitfarraj_logo/$name';
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path manque — le logo s\'affichera en carré gris.',
        );
      }
    });

    test('le dossier est déclaré au bundle', () {
      expect(declared, contains('assets/images/ajitfarraj_logo/'));
    });

    test('plus aucun écran ne cite un chemin de logo en clair', () {
      // Sept écrans recopiaient le même choix à quatre branches, et l'un
      // d'eux demandait 130 points de haut dans une barre qui en fait 56.
      final offenders = Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('ajitfarraj_logo'))
          .map((f) => f.path)
          .toList();

      expect(
        offenders,
        isEmpty,
        reason: 'Passez par AppLogo :\n  ${offenders.join('\n  ')}',
      );
    });
  });

  group('la variante servie', () {
    /// Rend un [AppLogo] et rapporte le chemin réellement demandé.
    Future<String> assetShown(
      WidgetTester tester, {
      required AppLogoVariant variant,
      required AppLocale locale,
      required Brightness brightness,
    }) async {
      AppColors.updateBrightness(brightness);

      await tester.pumpWidget(
        ProviderScope(
          // Une clé neuve à chaque appel : sans elle, Flutter met à jour le
          // ProviderScope existant, le notifier survit, et la surcharge de
          // langue n'est jamais relue.
          key: UniqueKey(),
          overrides: [localeProvider.overrideWith(() => _FixedLocale(locale))],
          child: MaterialApp(home: AppLogo(variant: variant, height: 30)),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));

      return (image.image as AssetImage).assetName;
    }

    testWidgets('le symbole ne bouge ni avec la langue ni avec le thème',
        (tester) async {
      // Il est en dégradé orange : il n'a rien à adapter, et un seul fichier
      // suffit.
      final seen = <String>{};
      for (final locale in AppLocale.values) {
        for (final b in Brightness.values) {
          seen.add(await assetShown(tester,
              variant: AppLogoVariant.mark, locale: locale, brightness: b));
        }
      }

      expect(seen, hasLength(1));
      expect(seen.single, endsWith('mark.png'));
    });

    testWidgets('le logotype suit la langue et le fond', (tester) async {
      // Son « tfarraj » est blanc sur sombre et noir sur clair : quatre
      // fichiers, et pas un de moins.
      final seen = <String>{};
      for (final locale in AppLocale.values) {
        for (final b in Brightness.values) {
          final path = await assetShown(tester,
              variant: AppLogoVariant.lockup, locale: locale, brightness: b);
          seen.add(path);
          expect(File(path).existsSync(), isTrue, reason: '$path est absent');
        }
      }

      expect(seen, hasLength(AppLocale.values.length * 2));
    });
  });

  tearDown(() => AppColors.updateBrightness(Brightness.dark));
}

class _FixedLocale extends LocaleNotifier {
  _FixedLocale(this._value);

  final AppLocale _value;

  @override
  AppLocale build() => _value;
}
