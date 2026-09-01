import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;

/// The contextual guided tours available in the app.
///
/// Each tour runs **once** per install (tracked in SharedPreferences) and can be
/// replayed on demand from "Comment ça marche".
enum GuidedTourId {
  /// First arrival on the home screen — what the app is and where things are.
  home,

  /// First time on the seat-selection screen — how to reserve.
  reserve;

  /// Storage key for the "already seen" flag.
  String get _prefsKey => 'guided_tour_seen_$name';
}

/// Tracks which tours the user has already completed, and which one (if any) is
/// currently showing.
///
/// A tour is marked seen when the user finishes it **or** skips it — being shown
/// the tour once is what matters, so a skip must not make it come back.
class GuidedTourController extends StateNotifier<GuidedTourId?> {
  GuidedTourController(this._prefs) : super(null);

  final SharedPreferences _prefs;

  /// Whether [id] has already been shown (completed or skipped).
  bool hasSeen(GuidedTourId id) => _prefs.getBool(id._prefsKey) ?? false;

  /// Show [id] unless it has already been seen or another tour is running.
  ///
  /// Safe to call from a screen's initState on every build/visit — it no-ops
  /// once the tour has been seen.
  void startIfUnseen(GuidedTourId id) {
    if (state != null || hasSeen(id)) return;
    state = id;
  }

  /// Force-show [id] even if already seen (the "Revoir le guide" entry point).
  void replay(GuidedTourId id) {
    state = id;
  }

  /// Close the running tour and remember it, so it does not reappear.
  Future<void> finish() async {
    final current = state;
    state = null;
    if (current != null) {
      await _prefs.setBool(current._prefsKey, true);
    }
  }

  /// Close the running tour WITHOUT remembering it (used when the screen is
  /// disposed mid-tour, so the user still gets it next time).
  void cancel() => state = null;

  /// Cancel only if [id] is the tour currently running.
  ///
  /// Called when a screen is popped (e.g. the Android back button) while its
  /// tour is up — otherwise the overlay would stay stranded on top of whatever
  /// screen comes next.
  void cancelIfActive(GuidedTourId id) {
    if (state == id) state = null;
  }

  /// Clear every "seen" flag — used by logout so the next account on this
  /// device is onboarded from scratch.
  Future<void> resetAll() async {
    state = null;
    for (final id in GuidedTourId.values) {
      await _prefs.remove(id._prefsKey);
    }
  }
}

/// The tour currently being displayed, or null when none is active.
final guidedTourControllerProvider =
    StateNotifierProvider<GuidedTourController, GuidedTourId?>((ref) {
  return GuidedTourController(ref.watch(sharedPreferencesProvider));
});
