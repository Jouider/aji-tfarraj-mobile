# Production Readiness — Changes Log

**Audit date:** 2026-03
**Branch:** `feature/loyalty-screens`
**Starting score:** 58 / 100
**Post-fix score:** ~83 / 100

This document records every change made during the production readiness audit. Changes are grouped by severity (blocker → high → recommended → hardening).

---

## Blockers Fixed

### 1. Android Release Signing

**Problem:** `android/app/build.gradle.kts` used the debug keystore for release builds — Google Play rejects APKs signed this way.

**Files changed:**
- `android/app/build.gradle.kts` — reads signing config from `key.properties`
- `android/key.properties.example` — template for developers to copy
- `android/app/proguard-rules.pro` — created with rules for Firebase, Dio, Google Sign-In, and Riverpod
- `.gitignore` — added `key.properties` and `*.jks` / `*.keystore`

**How to set up the release keystore:**

1. Generate a keystore (one-time):
   ```bash
   /Applications/Android\ Studio.app/Contents/jbr/Contents/Home/bin/keytool \
     -genkey -v -keystore android/app/release.keystore \
     -alias release -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Copy the example file and fill in your values:
   ```bash
   cp android/key.properties.example android/key.properties
   # Edit android/key.properties with your keystore path + passwords
   ```

3. Build a signed release APK:
   ```bash
   flutter build apk --release
   # or
   flutter build appbundle --release
   ```

4. Verify signature:
   ```bash
   apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
   ```

> **Never commit `key.properties` or `*.keystore` to git.**

---

### 2. Token Refresh Mechanism

**Problem:** The app had no way to renew an expiring Sanctum token. Users were silently logged out mid-session when the 7-day token expired.

**Files changed:**
- `lib/app/auth/token_storage.dart`
  - Stores `expires_at` alongside the token
  - `isExpiringSoon({threshold: 1 day})` helper
  - `sessionExpiredProvider` — global flag for session-expired banner
- `lib/app/config/app_config.dart`
  - Added `authRefresh = '/api/auth/refresh'` endpoint constant
  - Changed `currentBaseUrl` from `const` to `get` (supports `--dart-define=ENV=local`)
- `lib/features/auth/domain/user.dart`
  - `AuthResponse` now carries `expiresAt: DateTime?` parsed from `expires_at` (ISO 8601 UTC)
- `lib/features/auth/data/auth_repository.dart`
  - `refreshToken()` — `POST /api/auth/refresh` with current Bearer token, saves new token + expiry
  - `_saveAuthResponse()` — saves token and optional `expires_at` in one call
  - All auth paths (login, register, Google, Apple) now go through `_saveAuthResponse()`
  - `AuthNotifier._checkAuthStatus()` proactively refreshes if token expires within 1 day; falls through to `/api/auth/me` on network error; redirects to login on 401
- `lib/app/network/api_client.dart`
  - 401 interceptor: refresh token → retry original request (lock prevents concurrent refreshes)
  - `_isRefreshing` flag + `Completer<bool>` ensures only one refresh fires at a time
  - On refresh 401: clears session, sets `sessionExpiredProvider = true`
- `lib/features/auth/presentation/auth_landing_screen.dart`
  - Watches `sessionExpiredProvider`; shows a `_ErrorBanner` when `true`; clears flag after login

**Token refresh flow:**
```
Cold start:
  readToken() → null → unauthenticated
  readToken() → exists → isExpiringSoon()?
    YES → POST /api/auth/refresh
      200 → save new token → authenticated
      401 → clearToken → unauthenticated
      network error → fall through to /api/auth/me
    NO  → GET /api/auth/me
      200 → authenticated
      401 → clearToken → unauthenticated

Mid-session 401:
  Interceptor fires → POST /api/auth/refresh
    200 → retry original request
    401 → clearSession → sessionExpiredProvider = true → banner shown on auth_landing_screen
```

---

### 3. ErrorScreen Rewrite

**Problem:** `lib/features/error/error_screen.dart` had 4 placeholder TODOs, hardcoded French strings, and a retry button that did nothing.

**Files changed:**
- `lib/features/error/error_screen.dart` — full rewrite as `ConsumerWidget`, uses `stringsProvider` for all text, displays error message passed via route extras, wires retry button to `context.pop()`
- `lib/app/copywriting/copy_fr.dart` / `copy_ar.dart` — added `errorTitle` key
- `lib/app/localization/strings.dart` — wired `errorTitle` getter

---

## High Priority Fixed

### 4. Hardcoded Google OAuth Client ID Removed

**Problem:** `auth_repository.dart` hardcoded the iOS Google OAuth Client ID in Dart source — baked into the compiled binary and committed to version control.

**Fix:** Removed the `clientId` parameter entirely. `google_sign_in` auto-reads it from `GoogleService-Info.plist` (iOS) and `google-services.json` (Android).

**File changed:** `lib/features/auth/data/auth_repository.dart` — removed `clientId:` line

---

### 5. Blank Placeholder Screens Implemented

Three screens were user-reachable but rendered blank with TODO comments.

**`lib/features/reservation/reservation_success_screen.dart`**
- Implemented: success icon, localized title + body, "View Ticket" CTA (→ `/ticket`), "Back to Home" CTA

**`lib/features/show/sold_out_screen.dart`**
- Implemented: sold-out icon, localized message, "Browse Shows" button (→ `/`)

**`lib/features/error/error_screen.dart`**
- Implemented: error icon, localized title + body, back button, optional retry

**Copywriting additions:**

| Key | FR | AR |
|-----|----|----|
| `backToHome` | Retour à l'accueil | العودة للرئيسية |
| `browseShows` | Voir les émissions | استعراض البرامج |
| `reservationSuccessBody` | Votre réservation a été envoyée... | تم إرسال حجزك... |
| `errorTitle` | Une erreur s'est produite | حدث خطأ |

---

### 6. Hardcoded Strings Fixed

**`lib/features/loyalty/presentation/loyalty_screen.dart`**
- Replaced 2 × `Text('Voir tout')` with `Text(s.seeAll)` (FR: "Voir tout" / AR: "عرض الكل")

---

### 7. Build Environments

**Problem:** The app always pointed to production. Developers had to manually edit `app_config.dart` to test against a local server.

**Fix:** `currentBaseUrl` is now a getter driven by `--dart-define=ENV=`:

```bash
# Local development
flutter run --dart-define=ENV=local

# Production (default)
flutter run
flutter run --dart-define=ENV=prod
```

**File changed:** `lib/app/config/app_config.dart`

---

### 8. Tab Navigation State Preservation

**Problem:** `app_shell.dart` used `context.go()` to switch tabs. GoRouter rebuilt the entire widget subtree on every tab switch — scroll positions lost, providers re-fetched, animations restarted.

**Fix:** Migrated to `StatefulShellRoute.indexedStack` in GoRouter. Each tab lives in a persistent `Navigator` subtree that is never rebuilt on tab switch.

**Files changed:**
- `lib/app/router.dart` — replaced 4 top-level routes with `StatefulShellRoute.indexedStack` (5 branches: home, reservations, ticket, loyalty, profile)
- `lib/app/app_shell.dart` — now accepts `StatefulNavigationShell`; tab switching calls `shell.goBranch(index, initialLocation: index == shell.currentIndex)`

---

## Recommended Fixes

### 9. Ticket Cache Moved to Secure Storage

**Problem:** `ticket_repository.dart` cached QR ticket data (including QR tokens) in SharedPreferences — stored in cleartext on Android.

**Fix:** Replaced SharedPreferences with `flutter_secure_storage` (same encrypted storage used for auth tokens).

**File changed:** `lib/features/tickets/data/ticket_repository.dart`

```dart
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
```

---

### 10. iOS Permission Strings Localized to Arabic

**Problem:** `Info.plist` had camera and photo library permission descriptions in French only. iOS rejects apps that don't provide permission strings for each supported language.

**Files created:**
- `ios/Runner/fr.lproj/InfoPlist.strings` — French permission descriptions
- `ios/Runner/ar.lproj/InfoPlist.strings` — Arabic permission descriptions

**File changed:** `ios/Runner.xcodeproj/project.pbxproj`
- Added `fr` and `ar` to `knownRegions`
- Added `PBXFileReference`, `PBXVariantGroup`, `PBXBuildFile` entries
- Registered variant group in Runner Resources build phase

---

### 11. Session Expired UX

**Problem:** When a refresh attempt fails with 401, users were silently redirected to the login screen with no explanation.

**Fix:** `_clearSession()` in `api_client.dart` sets `sessionExpiredProvider = true`. `auth_landing_screen.dart` watches this provider and shows a red banner:

> "Votre session a expiré. Veuillez vous reconnecter." / "انتهت جلستك. يرجى تسجيل الدخول مجددًا."

The banner is dismissed automatically when the user completes login.

---

### 12. Unit Tests Added

**`test/api_exception_test.dart`** — 18 tests
- `ApiException.fromDioError` message parsing for all error types (timeout, connection error, all status codes)
- All 5 status-code boolean helpers (`isUnauthorized`, `isNotFound`, `isValidationError`, `isServerError`, `isCancelled`)
- Validation error field extraction

**`test/session_expired_provider_test.dart`** — 4 tests
- Initial state is `false`
- Can be set to `true`
- Can be reset to `false`
- Each `ProviderContainer` is isolated

**Bug caught by tests:**
- `ApiException.fromDioError` had a runtime cast error: `data['errors'] as Map<String, dynamic>?`
- Dio decodes JSON as `Map<dynamic, dynamic>`, not `Map<String, dynamic>`
- Fixed to: `(data['errors'] as Map?)?.cast<String, dynamic>()`

---

## Hardening Improvements

### 13. Dio Retry with Exponential Backoff

**File changed:** `lib/app/network/api_client.dart`

Transient network failures (timeouts, connection drops, 502/503/504) are automatically retried up to 3 times with exponential backoff:

| Attempt | Delay |
|---------|-------|
| 1st retry | 500 ms |
| 2nd retry | 1 000 ms |
| 3rd retry | 2 000 ms |

4xx errors (except 401) are never retried. The refresh token request and retried requests are excluded from retry via `extra['skipRefresh'] = true`.

---

### 14. ProviderObserver for Error Monitoring

**Files created/changed:**
- `lib/app/monitoring/provider_observer.dart` — `AppProviderObserver extends ProviderObserver`
- `lib/main.dart` — `observers: const [AppProviderObserver()]` added to `ProviderScope`

In debug mode: `debugPrint` to console.
In release mode: `FlutterError.reportError` — hooks into `FlutterError.onError` which can forward to Firebase Crashlytics.

**To add Crashlytics (future sprint):**
```dart
// in main(), after Firebase.initializeApp():
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

---

## Items Still Open

These were identified in the audit but not yet implemented:

| # | Issue | Priority |
|---|-------|----------|
| 1 | SSL/TLS certificate pinning | RECOMMENDED |
| 2 | Offline caching for shows + reservations (Hive/SQLite) | NICE-TO-HAVE |
| 3 | `connectivity_plus` pre-checks before requests | NICE-TO-HAVE |
| 4 | ProGuard rules verification | RECOMMENDED |
| 5 | Move `firebase_options.dart` to `.gitignore` | NICE-TO-HAVE |
| 6 | Scrub `.env` from git history (BFG Repo-Cleaner) | NICE-TO-HAVE |
| 7 | Stricter lint rules (`avoid_print`, `always_declare_return_types`) | NICE-TO-HAVE |
| 8 | Test coverage to 40%+ (repo unit tests, widget tests, integration) | RECOMMENDED |
| 9 | Forgot password flow — verify implementation is complete | HIGH |
| 10 | iOS push notification entitlements — verify in Xcode | HIGH |

---

## Pre-Release Verification Checklist

- [ ] `flutter test` — all tests pass
- [ ] `flutter build apk --release` — builds without error, signed with production keystore
- [ ] `apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk`
- [ ] `flutter build ipa --release` — builds without error, verified in Xcode Organizer
- [ ] **Token expiry**: Manually expire a Sanctum token in the DB, reopen app — verify graceful session restore or login redirect with banner
- [ ] **Cold start**: Kill app, reopen — verify session restored without re-login
- [ ] **Tab navigation**: Home → switch tabs → return → scroll position preserved
- [ ] **Offline**: Disable network after loading tickets → offline banner + QR still visible
- [ ] **ErrorScreen**: Trigger a 500 from backend → localized error + working back button
- [ ] **ReservationSuccess**: Complete a reservation → success screen shows summary + ticket CTA
- [ ] **Language**: Toggle to Arabic → all visible strings are in Arabic
- [ ] **Permissions (iOS)**: Install on device, trigger camera/photo — Arabic permission strings appear in Arabic mode
