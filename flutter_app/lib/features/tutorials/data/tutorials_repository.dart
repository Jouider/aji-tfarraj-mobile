import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;
import 'package:aji_tfarraj/features/tutorials/domain/tutorial.dart';

/// Where the tutorial clips are: `GET /api/app-config → tutorials`.
///
/// On the server rather than in the app, so a clip can be re-recorded or fixed
/// without a store release.
class TutorialsRepository {
  TutorialsRepository(this._client);

  final ApiClient _client;

  /// The raw `app-config` body — tutorials and pose demonstrations both read
  /// from it, so one request serves both. Null on any failure: never throws,
  /// because without the clips the app shows no video, and nothing else changes.
  Future<Object?> fetchAppConfig() async {
    try {
      final response = await _client.get<dynamic>(AppConfig.appConfig);
      final data = response.data;
      return (data is Map && data['data'] is Map) ? data['data'] : data;
    } catch (e) {
      if (kDebugMode) debugPrint('[Tutorials] fetch failed: $e');
      return null;
    }
  }
}

final tutorialsRepositoryProvider = Provider<TutorialsRepository>(
  (ref) => TutorialsRepository(ref.watch(apiClientProvider)),
);

/// `GET /api/app-config`, fetched once per session.
final appConfigJsonProvider = FutureProvider<Object?>(
  (ref) => ref.watch(tutorialsRepositoryProvider).fetchAppConfig(),
);

final tutorialsProvider = FutureProvider<Tutorials>(
  (ref) async =>
      Tutorials.fromAppConfig(await ref.watch(appConfigJsonProvider.future)),
);

/// The clip for a topic in the current language. Null while loading, after a
/// failure, or when the server has none — every entry point hides itself then.
final tutorialClipProvider =
    Provider.family<TutorialClip?, TutorialTopic>((ref, topic) {
  final tutorials = ref.watch(tutorialsProvider).valueOrNull ?? Tutorials.none;
  return tutorials.clipFor(topic, ref.watch(localeProvider));
});

/// Whether the first-time banner for a topic is still to be offered.
///
/// Offered until the member watches the clip or hides the banner, then never
/// again on this device. The "?" in the app bar stays for later.
class TutorialOfferNotifier extends FamilyNotifier<bool, TutorialTopic> {
  static String _key(TutorialTopic topic) => 'tutorial_offer_done_${topic.key}';

  @override
  bool build(TutorialTopic topic) =>
      !(ref.read(sharedPreferencesProvider).getBool(_key(topic)) ?? false);

  void dismiss() {
    if (!state) return;
    state = false;
    ref.read(sharedPreferencesProvider).setBool(_key(arg), true);
  }
}

final tutorialOfferProvider =
    NotifierProvider.family<TutorialOfferNotifier, bool, TutorialTopic>(
  TutorialOfferNotifier.new,
);
