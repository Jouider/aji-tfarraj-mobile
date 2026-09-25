import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';

/// Contrast is measurable, so it should be measured rather than eyeballed.
///
/// This exists because the gold call-to-action shipped white-on-gold at 2.1:1 —
/// unreadable, and below the floor even for large text. It looked fine to
/// whoever wrote it, because in the *dark* theme the token happened to resolve
/// to near-black. The light theme had the same button in white.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;

  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  /// WCAG AA: 4.5:1 for body text, 3:1 for large text. Button labels are large
  /// and bold, but a CTA is the last thing that should be borderline.
  const aaNormalText = 4.5;

  group('ink on the gold call-to-action', () {
    test('is readable, and by a wide margin', () {
      expect(
        contrast(AppColors.secondary, AppColors.onSecondary),
        greaterThanOrEqualTo(aaNormalText),
      );
    });

    /// The exact mistake this guard exists for.
    test('white would not be — hence the dedicated token', () {
      expect(
        contrast(AppColors.secondary, const Color(0xFFFFFFFF)),
        lessThan(3.0),
        reason: 'white on the gold is ~2.1:1; never use it',
      );
    });

    /// [AppColors.secondary] is one constant for both themes, so its ink must
    /// be too. A theme-dependent token here is what broke it last time.
    test('neither colour moves with the theme', () {
      const gold = AppColors.secondary;
      const ink = AppColors.onSecondary;

      // Both are compile-time constants; if either became a getter this stops
      // compiling, which is the point.
      expect(gold, isA<Color>());
      expect(ink, isA<Color>());
    });
  });

  group('ink on the orange call-to-action', () {
    /// Le dégradé de la charte ne supporte aucune encre d'un bout à l'autre :
    /// le blanc tombe à 3,1:1 sur l'orange clair, l'encre noire à 3,3:1 sur le
    /// rouge foncé. C'est la raison d'être d'un dégradé de bouton distinct, et
    /// ce test le rappelle à qui voudrait les réunir.
    test('the charter gradient carries no ink from end to end', () {
      final white = contrast(AppColors.primary, const Color(0xFFF7F8F8));
      final ink = contrast(AppColors.primaryDark, AppColors.onPrimary);

      expect(white, lessThan(aaNormalText));
      expect(ink, lessThan(aaNormalText));
    });

    test('the button gradient is readable at both ends', () {
      for (final end in [AppColors.primary, AppColors.primaryActionEnd]) {
        expect(
          contrast(end, AppColors.onPrimary),
          greaterThanOrEqualTo(aaNormalText),
          reason: 'un libellé de bouton se lit sur toute la longueur',
        );
      }
    });

    /// Ce qui reste vrai quoi qu'il arrive : le blanc n'a rien à faire sur
    /// l'orange clair, et l'encre noire rien à faire sur le rouge foncé.
    test('the two inks are never interchangeable', () {
      expect(
        contrast(AppColors.primary, const Color(0xFFFFFFFF)),
        lessThan(aaNormalText),
      );
      expect(
        contrast(AppColors.primaryDark, const Color(0xFFF7F8F8)),
        greaterThanOrEqualTo(aaNormalText),
        reason: 'le rouge foncé, lui, porte le blanc — pour un aplat uni',
      );
    });
  });
}
