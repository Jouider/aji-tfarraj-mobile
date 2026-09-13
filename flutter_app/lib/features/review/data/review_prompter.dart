import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;

/// Asking for a rating the way the stores want it asked.
///
/// The native dialog is quota-limited by Apple and Google: calling it does not
/// mean it appears, and there is no way to know whether it did. Two rules
/// follow from that, and this class exists to keep them:
///
/// 1. **Never behind a button.** A "rate us" button that silently does nothing
///    looks broken, and burns the quota. The manual entry opens the store page
///    instead ([openStoreListing]), which always works.
/// 2. **Only after a moment that went well**, and only for people who have come
///    back — someone who attended a recording, not someone who just installed.
///
/// Nobody is asked twice in a season: a long cooldown and a yearly cap sit on
/// top of the stores' own quotas, because a prompt that annoys someone costs a
/// one-star review.
abstract class ReviewLauncher {
  Future<bool> isAvailable();

  Future<void> requestReview();

  Future<void> openStoreListing({String? appStoreId});
}

class PluginReviewLauncher implements ReviewLauncher {
  const PluginReviewLauncher();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();

  @override
  Future<void> openStoreListing({String? appStoreId}) =>
      InAppReview.instance.openStoreListing(appStoreId: appStoreId);
}

class ReviewPrompter {
  ReviewPrompter({
    required SharedPreferences prefs,
    ReviewLauncher launcher = const PluginReviewLauncher(),
    DateTime Function() clock = DateTime.now,
  })  : _prefs = prefs,
        _launcher = launcher,
        _now = clock;

  final SharedPreferences _prefs;
  final ReviewLauncher _launcher;
  final DateTime Function() _now;

  /// Apple's own ceiling is three prompts a year; Google keeps its quota
  /// private. Staying under both is the only way to be sure.
  static const maxPromptsPerYear = 3;

  /// Long enough that a second ask lands in a different season of someone's
  /// life with the app, not the same week.
  static const cooldown = Duration(days: 60);

  /// One good evening is a coincidence; two is an opinion worth asking for.
  static const minGoodMoments = 2;

  static const _kGoodMoments = 'review_good_moments';
  static const _kLastPromptAt = 'review_last_prompt_at';
  static const _kPromptsThisYear = 'review_prompts_this_year';
  static const _kYearStartedAt = 'review_year_started_at';
  static const _kHandledManually = 'review_handled_manually';
  static const _kCountedMoments = 'review_counted_moments';

  /// The App Store id, for the manual "rate us" entry on iOS.
  static const appStoreId = '6760630862';

  int get goodMoments => _prefs.getInt(_kGoodMoments) ?? 0;

  /// Something went right: they attended a recording, or their booking was
  /// approved. Called from the screens that know it, never from a catch block.
  Future<void> recordGoodMoment() async {
    await _prefs.setInt(_kGoodMoments, goodMoments + 1);
  }

  /// Count a moment once and once only.
  ///
  /// The same attended recording comes back in the list on every refresh; each
  /// sighting must not raise the count, or someone gets asked after a single
  /// evening. [key] identifies the moment — a reservation id, typically.
  ///
  /// Returns whether this one counted.
  Future<bool> recordGoodMomentOnce(String key) async {
    final counted = _prefs.getStringList(_kCountedMoments) ?? const <String>[];
    if (counted.contains(key)) return false;

    await _prefs.setStringList(_kCountedMoments, [...counted, key]);
    await recordGoodMoment();
    return true;
  }

  /// Whether this is a fair moment to ask. Pure and synchronous, so the rules
  /// can be tested without touching a plugin.
  bool get shouldAsk {
    if (_prefs.getBool(_kHandledManually) ?? false) return false;
    if (goodMoments < minGoodMoments) return false;
    if (_promptsThisYear >= maxPromptsPerYear) return false;

    final last = _lastPromptAt;
    if (last != null && _now().difference(last) < cooldown) return false;

    return true;
  }

  /// Offer the native dialog, if this is a fair moment and the store is willing.
  ///
  /// Returns whether the dialog was requested — not whether it was shown, which
  /// neither store will tell us.
  Future<bool> askIfEarned() async {
    if (!shouldAsk) return false;
    if (!await _launcher.isAvailable()) return false;

    await _launcher.requestReview();
    await _recordAsked();
    return true;
  }

  /// The manual path, from the profile: always opens the store page, so it can
  /// sit behind a button without lying to anyone. Someone who goes there on
  /// purpose is never prompted automatically afterwards.
  Future<void> openStoreListing() async {
    await _prefs.setBool(_kHandledManually, true);
    await _launcher.openStoreListing(appStoreId: appStoreId);
  }

  DateTime? get _lastPromptAt {
    final raw = _prefs.getString(_kLastPromptAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  int get _promptsThisYear {
    final startedRaw = _prefs.getString(_kYearStartedAt);
    final started = startedRaw == null ? null : DateTime.tryParse(startedRaw);
    if (started == null || _now().difference(started) > const Duration(days: 365)) {
      return 0;
    }
    return _prefs.getInt(_kPromptsThisYear) ?? 0;
  }

  Future<void> _recordAsked() async {
    final now = _now();
    final startedRaw = _prefs.getString(_kYearStartedAt);
    final started = startedRaw == null ? null : DateTime.tryParse(startedRaw);

    // A fresh year starts with this prompt when the last one is over a year old.
    if (started == null || now.difference(started) > const Duration(days: 365)) {
      await _prefs.setString(_kYearStartedAt, now.toIso8601String());
      await _prefs.setInt(_kPromptsThisYear, 1);
    } else {
      await _prefs.setInt(_kPromptsThisYear, (_prefs.getInt(_kPromptsThisYear) ?? 0) + 1);
    }

    await _prefs.setString(_kLastPromptAt, now.toIso8601String());
  }
}

final reviewPrompterProvider = Provider<ReviewPrompter>((ref) {
  return ReviewPrompter(prefs: ref.watch(sharedPreferencesProvider));
});
