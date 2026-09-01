import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/features/guided_tour/data/guided_tour_controller.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;

/// The guided tour must appear exactly once per install, never trap the user,
/// and never leak between accounts on a shared device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  Future<GuidedTourController> makeController() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container.read(guidedTourControllerProvider.notifier);
  }

  GuidedTourId? active() => container.read(guidedTourControllerProvider);

  group('showing a tour', () {
    test('no tour is active on a fresh install', () async {
      await makeController();
      expect(active(), isNull);
    });

    test('startIfUnseen shows the tour the first time', () async {
      final c = await makeController();

      c.startIfUnseen(GuidedTourId.home);

      expect(active(), GuidedTourId.home);
    });

    test('finishing marks it seen so it never comes back', () async {
      final c = await makeController();
      c.startIfUnseen(GuidedTourId.home);

      await c.finish();

      expect(active(), isNull);
      expect(c.hasSeen(GuidedTourId.home), isTrue);

      c.startIfUnseen(GuidedTourId.home);
      expect(active(), isNull, reason: 'must not reappear once seen');
    });

    test('two tours do not overlap', () async {
      final c = await makeController();
      c.startIfUnseen(GuidedTourId.home);

      c.startIfUnseen(GuidedTourId.reserve);

      expect(active(), GuidedTourId.home,
          reason: 'a second tour must not hijack the running one');
    });

    test('tours are tracked independently', () async {
      final c = await makeController();
      c.startIfUnseen(GuidedTourId.home);
      await c.finish();

      c.startIfUnseen(GuidedTourId.reserve);

      expect(active(), GuidedTourId.reserve);
      expect(c.hasSeen(GuidedTourId.reserve), isFalse);
    });
  });

  group('leaving a tour', () {
    test('cancel closes it WITHOUT marking it seen (user gets it later)',
        () async {
      final c = await makeController();
      c.startIfUnseen(GuidedTourId.home);

      c.cancel();

      expect(active(), isNull);
      expect(c.hasSeen(GuidedTourId.home), isFalse);

      c.startIfUnseen(GuidedTourId.home);
      expect(active(), GuidedTourId.home, reason: 'not seen yet, so show it');
    });

    test('cancelIfActive only closes the matching tour', () async {
      final c = await makeController();
      c.startIfUnseen(GuidedTourId.home);

      c.cancelIfActive(GuidedTourId.reserve);
      expect(active(), GuidedTourId.home, reason: 'different tour, leave it');

      c.cancelIfActive(GuidedTourId.home);
      expect(active(), isNull);
    });
  });

  group('replay', () {
    test('replay shows a tour again even once seen', () async {
      final c = await makeController();
      c.startIfUnseen(GuidedTourId.home);
      await c.finish();

      c.replay(GuidedTourId.home);

      expect(active(), GuidedTourId.home);
    });
  });

  group('shared device', () {
    test('resetAll clears every seen flag on logout', () async {
      final c = await makeController();
      c.startIfUnseen(GuidedTourId.home);
      await c.finish();
      c.startIfUnseen(GuidedTourId.reserve);
      await c.finish();

      await c.resetAll();

      expect(active(), isNull);
      expect(c.hasSeen(GuidedTourId.home), isFalse);
      expect(c.hasSeen(GuidedTourId.reserve), isFalse);
    });
  });

  group('persistence', () {
    test('a seen flag survives an app restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final first = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      await first.read(guidedTourControllerProvider.notifier)
        ..startIfUnseen(GuidedTourId.home);
      await first.read(guidedTourControllerProvider.notifier).finish();
      first.dispose();

      // New container = new app launch, same storage.
      final second = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);
      final c2 = second.read(guidedTourControllerProvider.notifier);

      expect(c2.hasSeen(GuidedTourId.home), isTrue);
      c2.startIfUnseen(GuidedTourId.home);
      expect(second.read(guidedTourControllerProvider), isNull);
    });
  });
}
