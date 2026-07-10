import 'dart:io' show Platform;

import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/app/auth/token_storage.dart' show authStateProvider;
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;
import 'package:aji_tfarraj/features/referral/data/referral_repository.dart';

/// Set once we've read the deferred deep link (install referrer / clipboard) on
/// first launch — so we never read the clipboard (iOS paste prompt) again.
const String _kReferralCheckedFlag = 'referral_attribution_checked';

/// Persisted referral code captured from a deferred deep link. Survives an app
/// kill so a new user who installs via a CP link is still attributed when they
/// reserve later. Cleared once a reservation is created.
const String _kPendingReferralCode = 'pending_referral_code';

/// Persisted **raw** referral token from a `/r/{token}` deep link (live,
/// cold-start, or deferred install). Kept until we can resolve it *authenticated*
/// so the backend binds the permanent referrer link. Survives an app kill and an
/// unauthenticated tap (user not yet logged in). Cleared once bound.
const String _kPendingReferralToken = 'pending_referral_token';

/// Handles **deferred** deep-link attribution for CP (chargé public) referral
/// links — the case where a user clicks a CP link *before* installing the app,
/// so the `/r/{token}` deep link is lost during install.
///
/// - **Android** → Google Play Install Referrer (silent, reliable). The backend
///   embeds `referral_token={token}` in the Play Store `&referrer=` param.
/// - **iOS** → clipboard. The web landing writes `referral_token={token}` to the
///   clipboard at install tap; we read it once on first launch (iOS 14+ shows a
///   paste prompt — expected). Manual code entry remains the fallback.
///
/// Live (app-already-installed) links are handled by [DeepLinkService] +
/// the referral landing screen, which also persist via [persistCode].
class ReferralAttributionService {
  final Ref _ref;

  ReferralAttributionService(this._ref);

  SharedPreferences get _prefs => _ref.read(sharedPreferencesProvider);

  /// Referral code captured from a deferred deep link in a previous session.
  String? get storedCode => _prefs.getString(_kPendingReferralCode);

  /// Persist a referral code in-memory (current session) **and** on disk so it
  /// survives an app kill before the reservation completes.
  Future<void> persistCode(String code) async {
    if (code.isEmpty) return;
    await _prefs.setString(_kPendingReferralCode, code);
    _ref.read(pendingReferralCodeProvider.notifier).state = code;
  }

  /// Clear the captured code (call after a reservation is successfully created).
  Future<void> clearStoredCode() async {
    await _prefs.remove(_kPendingReferralCode);
  }

  /// Raw referral token awaiting an authenticated resolve (see
  /// [resolvePendingTokenIfAuthenticated]).
  String? get pendingToken => _prefs.getString(_kPendingReferralToken);

  /// Persist a raw referral token from a `/r/{token}` deep link so we can resolve
  /// it *authenticated* once the user is (or becomes) logged in. Survives an app
  /// kill, so a tap made while logged out is still bound after the next login.
  Future<void> persistToken(String token) async {
    if (token.isEmpty) return;
    await _prefs.setString(_kPendingReferralToken, token);
  }

  Future<void> _clearPendingToken() async {
    await _prefs.remove(_kPendingReferralToken);
  }

  /// If a referral token is pending **and** the user is authenticated, resolve it
  /// via the authenticated endpoint so the backend binds the **permanent**
  /// referrer link (`referrer_user_id`). After that, every future reservation is
  /// attributed to the CP automatically — the `referral_code` field no longer
  /// matters, and the user never has to re-tap the link.
  ///
  /// Fire-and-forget from startup (post-auth) and whenever auth becomes available
  /// (login / register / social). Idempotent and fail-safe:
  /// - no pending token → no-op.
  /// - not authenticated → keep the token, retry after the user logs in.
  /// - resolve failure → keep the token, retry next launch.
  /// - success → persist the code (form fallback) and clear the pending token.
  Future<void> resolvePendingTokenIfAuthenticated() async {
    final token = pendingToken;
    if (token == null || token.isEmpty) return;

    final authToken = _ref.read(authStateProvider).valueOrNull;
    if (authToken == null || authToken.isEmpty) return; // resolve after login

    try {
      final resolved = await _ref
          .read(referralRepositoryProvider)
          .resolveLinkAuthenticated(token);
      // Backend has now bound the permanent link; keep the code as a form
      // fallback for the reserve screen, then drop the pending token.
      await persistCode(resolved.referralCode);
      await _clearPendingToken();
    } catch (e) {
      // Keep the pending token so we retry on the next auth change / launch.
      if (kDebugMode) {
        debugPrint('[ReferralAttribution] authed resolve failed: $e');
      }
    }
  }

  /// Re-populate the in-memory pending-code provider from disk at startup, so a
  /// code captured in a previous session is still pre-filled on the reserve
  /// screen after an app restart.
  void hydratePending() {
    final code = storedCode;
    if (code != null && code.isNotEmpty) {
      _ref.read(pendingReferralCodeProvider.notifier).state = code;
    }
  }

  /// Read the deferred deep link **once** on first launch, resolve it to a
  /// referral code, and persist it. Fire-and-forget from app startup.
  ///
  /// Fail-open semantics:
  /// - already-checked → no-op (never re-read the clipboard).
  /// - no token found (organic install) → mark checked, done.
  /// - platform read or network/resolve failure → leave the flag UNSET so we
  ///   retry on the next launch (a CP install must not lose attribution to a
  ///   flaky first launch).
  Future<void> captureOnFirstLaunch() async {
    if (_prefs.getBool(_kReferralCheckedFlag) == true) return;

    String? token;
    try {
      token = await _readDeferredToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[ReferralAttribution] read failed: $e');
      return; // retry next launch
    }

    if (token == null || token.isEmpty) {
      // Organic install (no CP link). Mark checked so we don't prompt again.
      await _prefs.setBool(_kReferralCheckedFlag, true);
      return;
    }

    // Persist the raw token so that once this fresh install registers/logs in,
    // resolvePendingTokenIfAuthenticated binds the permanent referrer link.
    // Fixes the gap where sign-up captured no parrainage on its own.
    await persistToken(token);

    try {
      final resolved =
          await _ref.read(referralRepositoryProvider).resolveLink(token);
      await persistCode(resolved.referralCode);
      await _prefs.setBool(_kReferralCheckedFlag, true);
    } catch (e) {
      // Network/resolve failure — keep the flag unset so we retry next launch.
      if (kDebugMode) debugPrint('[ReferralAttribution] resolve failed: $e');
    }
  }

  Future<String?> _readDeferredToken() async {
    String raw = '';
    if (Platform.isAndroid) {
      final details = await AndroidPlayInstallReferrer.installReferrer;
      raw = details.installReferrer ?? '';
    } else if (Platform.isIOS) {
      final data = await Clipboard.getData('text/plain');
      raw = data?.text ?? '';
    }
    return parseToken(raw);
  }

  /// Extract the token from a `referral_token=<token>` payload. Handles a bare
  /// value, a query-like blob (`utm_source=x&referral_token=AB`), and a still
  /// URL-encoded referrer (`referral_token%3DAB`). Returns null when absent.
  @visibleForTesting
  static String? parseToken(String raw) {
    if (raw.isEmpty) return null;
    // The Play referrer / clipboard value may arrive URL-encoded.
    String decoded = raw;
    try {
      decoded = Uri.decodeComponent(raw);
    } catch (_) {
      // Not valid percent-encoding — use the raw string as-is.
    }
    if (!decoded.contains('referral_token')) return null;
    final match = RegExp(r'referral_token=([^&\s]+)').firstMatch(decoded);
    final token = match?.group(1)?.trim();
    return (token == null || token.isEmpty) ? null : token;
  }
}

final referralAttributionServiceProvider =
    Provider<ReferralAttributionService>(
  (ref) => ReferralAttributionService(ref),
);
