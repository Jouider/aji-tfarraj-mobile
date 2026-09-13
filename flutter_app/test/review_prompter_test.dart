import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/features/review/data/review_prompter.dart';

/// Records what would have been asked of the store, so the rules can be tested
/// without a plugin — and without burning a real quota.
class _FakeLauncher implements ReviewLauncher {
  _FakeLauncher({this.available = true});

  final bool available;
  int requested = 0;
  int listingOpened = 0;
  String? lastAppStoreId;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requested++;

  @override
  Future<void> openStoreListing({String? appStoreId}) async {
    listingOpened++;
    lastAppStoreId = appStoreId;
  }
}

void main() {
  late DateTime now;
  DateTime clock() => now;

  Future<SharedPreferences> prefsWith([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  setUp(() => now = DateTime(2026, 9, 13, 12));

  group('who gets asked', () {
    test('someone who just installed is not asked', () async {
      final launcher = _FakeLauncher();
      final p = ReviewPrompter(
          prefs: await prefsWith(), launcher: launcher, clock: clock);

      expect(p.shouldAsk, isFalse);
      expect(await p.askIfEarned(), isFalse);
      expect(launcher.requested, 0);
    });

    test('one good evening is not enough', () async {
      final p = ReviewPrompter(
          prefs: await prefsWith(), launcher: _FakeLauncher(), clock: clock);

      await p.recordGoodMoment();

      expect(p.goodMoments, 1);
      expect(p.shouldAsk, isFalse);
    });

    test('two good evenings earn the question', () async {
      final launcher = _FakeLauncher();
      final p = ReviewPrompter(
          prefs: await prefsWith(), launcher: launcher, clock: clock);

      await p.recordGoodMoment();
      await p.recordGoodMoment();

      expect(p.shouldAsk, isTrue);
      expect(await p.askIfEarned(), isTrue);
      expect(launcher.requested, 1);
    });

    /// On a device with no Play Store, or an iOS build where the dialog is
    /// unavailable, nothing must be recorded — otherwise the one real chance
    /// is spent on a dialog nobody saw.
    test('an unavailable store spends nothing', () async {
      final launcher = _FakeLauncher(available: false);
      final p = ReviewPrompter(
          prefs: await prefsWith({'review_good_moments': 5}),
          launcher: launcher,
          clock: clock);

      expect(await p.askIfEarned(), isFalse);
      expect(launcher.requested, 0);
      expect(p.shouldAsk, isTrue, reason: 'still owed, for a later day');
    });
  });

  group('how often', () {
    test('nobody is asked twice in the same season', () async {
      final launcher = _FakeLauncher();
      final prefs = await prefsWith({'review_good_moments': 5});
      final p = ReviewPrompter(prefs: prefs, launcher: launcher, clock: clock);

      expect(await p.askIfEarned(), isTrue);

      now = now.add(const Duration(days: 59));
      expect(p.shouldAsk, isFalse);
      expect(await p.askIfEarned(), isFalse);
      expect(launcher.requested, 1);
    });

    test('after the cooldown, once more', () async {
      final launcher = _FakeLauncher();
      final p = ReviewPrompter(
          prefs: await prefsWith({'review_good_moments': 5}),
          launcher: launcher,
          clock: clock);

      expect(await p.askIfEarned(), isTrue);
      now = now.add(const Duration(days: 61));

      expect(await p.askIfEarned(), isTrue);
      expect(launcher.requested, 2);
    });

    /// Apple's own ceiling. Asking a fourth time cannot work anyway.
    test('three times a year, and no more', () async {
      final launcher = _FakeLauncher();
      final p = ReviewPrompter(
          prefs: await prefsWith({'review_good_moments': 9}),
          launcher: launcher,
          clock: clock);

      for (var i = 0; i < 3; i++) {
        expect(await p.askIfEarned(), isTrue, reason: 'prompt ${i + 1}');
        now = now.add(const Duration(days: 61));
      }

      expect(await p.askIfEarned(), isFalse, reason: 'the fourth in one year');
      expect(launcher.requested, 3);

      // A year after the first, the count starts over.
      now = now.add(const Duration(days: 200));
      expect(await p.askIfEarned(), isTrue);
      expect(launcher.requested, 4);
    });
  });

  group('counting a moment once', () {
    test('the same evening never counts twice', () async {
      final p = ReviewPrompter(
          prefs: await prefsWith(), launcher: _FakeLauncher(), clock: clock);

      expect(await p.recordGoodMomentOnce('reservation-42'), isTrue);
      expect(await p.recordGoodMomentOnce('reservation-42'), isFalse);
      expect(await p.recordGoodMomentOnce('reservation-42'), isFalse);

      expect(p.goodMoments, 1, reason: 'one evening, however often the list refreshes');
      expect(p.shouldAsk, isFalse);
    });

    test('two different evenings earn the question', () async {
      final launcher = _FakeLauncher();
      final p = ReviewPrompter(
          prefs: await prefsWith(), launcher: launcher, clock: clock);

      await p.recordGoodMomentOnce('reservation-42');
      await p.recordGoodMomentOnce('reservation-77');

      expect(p.goodMoments, 2);
      expect(await p.askIfEarned(), isTrue);
      expect(launcher.requested, 1);
    });
  });

  group('the manual way', () {
    test('opens the store page with the App Store id', () async {
      final launcher = _FakeLauncher();
      final p = ReviewPrompter(
          prefs: await prefsWith(), launcher: launcher, clock: clock);

      await p.openStoreListing();

      expect(launcher.listingOpened, 1);
      expect(launcher.lastAppStoreId, ReviewPrompter.appStoreId);
      expect(launcher.requested, 0, reason: 'the quota-limited dialog is untouched');
    });

    /// Someone who went to the store themselves has had their say.
    test('stops the automatic prompt afterwards', () async {
      final launcher = _FakeLauncher();
      final p = ReviewPrompter(
          prefs: await prefsWith({'review_good_moments': 5}),
          launcher: launcher,
          clock: clock);

      expect(p.shouldAsk, isTrue);
      await p.openStoreListing();

      expect(p.shouldAsk, isFalse);
      expect(await p.askIfEarned(), isFalse);
    });
  });
}
