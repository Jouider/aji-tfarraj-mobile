import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/campaigns/domain/campaign.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;

/// Qui demande : l'installation, la plateforme, la version. Le jeton, lui,
/// part tout seul avec l'ApiClient quand la personne est connectée.
class CampaignCaller {
  const CampaignCaller({
    required this.deviceId,
    required this.platform,
    required this.appVersion,
  });

  final String deviceId;

  /// `ios` | `android`
  final String platform;
  final String appVersion;

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'platform': platform,
        'app_version': appVersion,
      };
}

/// L'identifiant d'installation : un UUID aléatoire, créé au premier
/// lancement et gardé dans les préférences. Ce n'est pas l'identifiant
/// publicitaire : il ne sert qu'à compter les affichages d'une personne
/// qui n'est pas connectée.
String installId(SharedPreferences prefs) {
  const key = 'campaign_device_id';
  final existing = prefs.getString(key);
  if (existing != null && existing.length >= 8) return existing;

  final rnd = Random.secure();
  final b = List<int>.generate(16, (_) => rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variante RFC 4122
  String hex(int from, int to) => b
      .sublist(from, to)
      .map((x) => x.toRadixString(16).padLeft(2, '0'))
      .join();
  final id =
      '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  prefs.setString(key, id);
  return id;
}

/// La version envoyée au serveur. `--dart-define=CAMPAIGN_APP_VERSION=…` la
/// remplace ; une build de debug envoie 99.0.0, pour voir les campagnes de
/// test (« version minimum 99.0.0 ») que personne d'autre ne voit.
String campaignAppVersion(String installed) {
  const override = String.fromEnvironment('CAMPAIGN_APP_VERSION');
  if (override.isNotEmpty) return override;
  if (kDebugMode) return '99.0.0';
  return installed;
}

String campaignPlatform() =>
    defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

/// `GET /api/campaigns` et `POST /api/campaigns/{id}/events`.
class CampaignsRepository {
  CampaignsRepository(this._api, this._caller);

  final ApiClient _api;
  final Future<CampaignCaller> Function() _caller;

  Future<CampaignFeed> fetch() async {
    final who = await _caller();
    final res = await _api.get<Map<String, dynamic>>(
      '/api/campaigns',
      queryParameters: who.toJson(),
    );
    return CampaignFeed.fromJson(res.data ?? const {});
  }

  /// Envoyé sans attendre, erreurs ignorées : une campagne ne bloque
  /// jamais l'app. `impression` | `click` | `dismiss` | `never`.
  Future<void> event(Campaign c, String event) async {
    try {
      final who = await _caller();
      await _api.post<dynamic>(
        '/api/campaigns/${c.id}/events',
        data: {'event': event, 'placement': c.placement, ...who.toJson()},
      );
    } catch (_) {
      // Ignoré : le compteur du serveur rate un événement, l'app continue.
    }
  }
}

final campaignCallerProvider =
    Provider<Future<CampaignCaller> Function()>((ref) {
  return () async {
    final prefs = ref.read(sharedPreferencesProvider);
    String installed = '';
    try {
      installed = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    return CampaignCaller(
      deviceId: installId(prefs),
      platform: campaignPlatform(),
      appVersion: campaignAppVersion(installed),
    );
  };
});

final campaignsRepositoryProvider = Provider<CampaignsRepository>((ref) {
  return CampaignsRepository(
    ref.watch(apiClientProvider),
    ref.watch(campaignCallerProvider),
  );
});
