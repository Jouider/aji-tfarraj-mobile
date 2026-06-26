import 'dart:io' show Platform;

import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
