import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/app/auth/token_storage.dart';

// ---------------------------------------------------------------------------
// Tests for sessionExpiredProvider — a simple StateProvider<bool>
// ---------------------------------------------------------------------------

void main() {
  group('sessionExpiredProvider', () {
    test('initial state is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(sessionExpiredProvider), isFalse);
    });

    test('can be set to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sessionExpiredProvider.notifier).state = true;

      expect(container.read(sessionExpiredProvider), isTrue);
    });

    test('can be reset to false after being set to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(sessionExpiredProvider.notifier).state = true;
      expect(container.read(sessionExpiredProvider), isTrue);

      container.read(sessionExpiredProvider.notifier).state = false;
      expect(container.read(sessionExpiredProvider), isFalse);
    });

    test('is independent between containers', () {
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();
      addTearDown(container1.dispose);
      addTearDown(container2.dispose);

      container1.read(sessionExpiredProvider.notifier).state = true;

      expect(container1.read(sessionExpiredProvider), isTrue);
      expect(container2.read(sessionExpiredProvider), isFalse);
    });
  });
}
