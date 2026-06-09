// ignore_for_file: avoid_print

/// Integration test that captures screenshots of every major screen.
///
/// Run on a connected device / simulator:
///
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/screenshot_test.dart \
///     -d <device-id>
///
/// Screenshots land in flutter_app/screenshots/.
library screenshot_test;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/main.dart' show AjiTfarrajApp;
import 'package:aji_tfarraj/app/auth/token_storage.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/app/monitoring/provider_observer.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/auth/domain/user.dart';
import 'package:aji_tfarraj/features/shows/data/shows_repository.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart';

import 'helpers/mock_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock implementations
// ─────────────────────────────────────────────────────────────────────────────

/// TokenStorage that always returns a valid mock token (no keychain access).
class _MockTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => 'mock-token-for-screenshots';

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> clearToken() async {}

  @override
  Future<DateTime?> readExpiresAt() async => null;

  @override
  Future<bool> isExpiringSoon({
    Duration threshold = const Duration(days: 1),
  }) async =>
      false;
}

/// AuthRepository that returns the mock user without any network calls.
class _MockAuthRepository extends AuthRepository {
  _MockAuthRepository()
      : super(
          Dio(BaseOptions(baseUrl: 'http://localhost')),
          _MockTokenStorage(),
        );

  @override
  Future<User> me() async => mockUser;

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<void> logout() async {}
}

/// ShowsRepository that returns mock shows without any network calls.
class _MockShowsRepository extends ShowsRepository {
  _MockShowsRepository(Ref ref)
      : super(
          apiClient: ApiClient(
            tokenStorage: _MockTokenStorage(),
            ref: ref,
          ),
        );

  @override
  Future<PaginatedShowsResponse> fetchShowsWithParams(
    ShowsQueryParams params,
  ) async {
    // Small delay to simulate realistic loading
    await Future.delayed(const Duration(milliseconds: 100));
    return PaginatedShowsResponse(
      shows: mockShows,
      currentPage: 1,
      lastPage: 1,
      total: mockShows.length,
      hasMore: false,
    );
  }

  @override
  Future<Show> fetchShowDetail(int id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return mockShows.firstWhere(
      (s) => s.id == id,
      orElse: () => mockShows.first,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Screenshots — Authenticated flow', () {
    testWidgets('Capture all main screens', (tester) async {
      // Initialise locale formatters (same as production main())
      await initializeDateFormatting('fr_FR', null);
      await initializeDateFormatting('ar', null);

      // Use a real SharedPreferences so notifications / locale prefs work
      final prefs = await SharedPreferences.getInstance();

      final mockStorage = _MockTokenStorage();

      // Pump the full app with mocked providers
      await tester.pumpWidget(
        ProviderScope(
          observers: const [AppProviderObserver()],
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(mockStorage),
            authRepositoryProvider.overrideWithValue(_MockAuthRepository()),
            showsRepositoryProvider.overrideWith(
              (ref) => _MockShowsRepository(ref),
            ),
          ],
          child: const AjiTfarrajApp(),
        ),
      );

      // Let the splash screen animate + auth guard redirect to home
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ── 01 Home ──────────────────────────────────────────────────────────
      await binding.takeScreenshot('01_home');
      print('[test] 📸 01_home');

      // ── 02 Browse ────────────────────────────────────────────────────────
      await tester.tap(find.byIcon(Icons.explore_outlined).first);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('02_browse');
      print('[test] 📸 02_browse');

      // ── 03 My Reservations ───────────────────────────────────────────────
      await tester.tap(find.byIcon(Icons.calendar_today_outlined).first);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('03_my_reservations');
      print('[test] 📸 03_my_reservations');

      // ── 04 Ticket ────────────────────────────────────────────────────────
      await tester.tap(find.byIcon(Icons.confirmation_number_outlined).first);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('04_ticket');
      print('[test] 📸 04_ticket');

      // ── 05 Profile ───────────────────────────────────────────────────────
      await tester.tap(find.byIcon(Icons.person_outline).first);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('05_profile');
      print('[test] 📸 05_profile');

      // ── 06 Show detail ───────────────────────────────────────────────────
      // Go back to Home and open the first show card
      await tester.tap(find.byIcon(Icons.movie_outlined).first);
      await tester.pumpAndSettle();
      // Find first tappable show card — try a common pattern
      final showCards = find.byType(InkWell);
      if (showCards.evaluate().isNotEmpty) {
        await tester.tap(showCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await binding.takeScreenshot('06_show_detail');
        print('[test] 📸 06_show_detail');
      }
    });
  });

  group('Screenshots — Auth flow', () {
    testWidgets('Capture auth screens', (tester) async {
      await initializeDateFormatting('fr_FR', null);
      await initializeDateFormatting('ar', null);

      final prefs = await SharedPreferences.getInstance();

      // Use an empty token storage so the router lands on auth screens
      final emptyStorage = _EmptyTokenStorage();

      await tester.pumpWidget(
        ProviderScope(
          observers: const [AppProviderObserver()],
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(emptyStorage),
            authRepositoryProvider.overrideWithValue(_MockAuthRepository()),
            showsRepositoryProvider.overrideWith(
              (ref) => _MockShowsRepository(ref),
            ),
          ],
          child: const AjiTfarrajApp(),
        ),
      );

      // Splash → auth landing (unauthenticated)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ── 07 Auth Landing ──────────────────────────────────────────────────
      await binding.takeScreenshot('07_auth_landing');
      print('[test] 📸 07_auth_landing');

      // ── 08 Login ─────────────────────────────────────────────────────────
      // Try to find a "Se connecter" / login button
      final loginButton = find.text('Se connecter');
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('08_login');
        print('[test] 📸 08_login');
        // Go back
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      }

      // ── 09 Register ──────────────────────────────────────────────────────
      final registerButton = find.text('Créer un compte');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('09_register');
        print('[test] 📸 09_register');
      }
    });
  });
}

/// TokenStorage that always reports no token (unauthenticated state).
class _EmptyTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => null;

  @override
  Future<bool> hasToken() async => false;

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> clearToken() async {}

  @override
  Future<DateTime?> readExpiresAt() async => null;

  @override
  Future<bool> isExpiringSoon({
    Duration threshold = const Duration(days: 1),
  }) async =>
      false;
}
