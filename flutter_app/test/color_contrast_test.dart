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

  group('ink on the other filled buttons', () {
    test('white on the maroon primary is readable', () {
      expect(
        contrast(AppColors.primary, const Color(0xFFFFFFFF)),
        greaterThanOrEqualTo(aaNormalText),
      );
    });
  });
}
