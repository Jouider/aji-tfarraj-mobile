import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/reservation/booking_bottom_bar_widget.dart';

/// Une barre collée en bas réserve la place de la barre d'onglets UNE fois.
///
/// Le piège est invisible en lecture : la marge du bas et un `SafeArea` lisent
/// tous les deux `MediaQuery.padding.bottom`, et les mettre côte à côte
/// applique l'inset deux fois. Tant que le shell posait la barre d'onglets sur
/// le contenu, cet inset valait zéro dans le corps de l'écran et le bug ne
/// coûtait rien. Depuis que le contenu file sous la barre en verre
/// (`extendBody: true`), Flutter y met l'encombrement de cette barre :
///
///   bottom = max(padding.bottom, bottomWidgetsHeight)   // scaffold.dart
///
/// soit ~102 points sur un iPhone récent. Deux fois 102, et l'écran gagne une
/// bande vide de 200 points au-dessus de la barre d'onglets.
///
/// Ce test rejoue exactement cette condition : un inset de 102, et la barre ne
/// doit laisser QUE 102 sous son contenu.
void main() {
  const s = AppStrings(AppLocale.fr);

  /// Ce que le shell donne à l'écran d'une réservation : la hauteur de la
  /// barre d'onglets flottante (6 de marge + 62 de pilule + 34 d'indicateur).
  const navBarFootprint = 102.0;

  Future<void> pumpBar(WidgetTester tester, {required double bottomInset}) {
    return tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: BookingBottomBar(
                    isLoading: false,
                    isSoldOut: false,
                    agreedToTerms: true,
                    onConfirm: () {},
                    s: s,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// L'espace entre le bas du bouton de confirmation et le bas de la barre.
  double gapUnderButton(WidgetTester tester) {
    final bar = tester.getRect(find.byType(BookingBottomBar));
    final button = tester.getRect(find.byType(ElevatedButton));
    return bar.bottom - button.bottom;
  }

  testWidgets('la barre réserve la place de la barre d\'onglets une seule fois',
      (tester) async {
    await tester.pumpWidget(const SizedBox());
    await pumpBar(tester, bottomInset: navBarFootprint);

    final gap = gapUnderButton(tester);

    // 102 pour la barre d'onglets + les 12 de respiration de la barre.
    expect(
      gap,
      closeTo(navBarFootprint + 12, 1),
      reason: 'La barre laisse $gap points sous le bouton. '
          'Au double (${navBarFootprint * 2 + 12}), l\'inset est appliqué '
          'deux fois — marge du bas ET SafeArea.',
    );
  });

  testWidgets('sans barre d\'onglets, elle ne réserve que l\'indicateur',
      (tester) async {
    // Le même écran ouvert hors du shell : `padding.bottom` redevient
    // l'indicateur d'accueil, et la barre doit suivre.
    await pumpBar(tester, bottomInset: 34);

    expect(gapUnderButton(tester), closeTo(34 + 12, 1));
  });

  testWidgets('sur un téléphone sans encoche, elle ne réserve rien de plus',
      (tester) async {
    await pumpBar(tester, bottomInset: 0);

    expect(gapUnderButton(tester), closeTo(12, 1));
  });
}
