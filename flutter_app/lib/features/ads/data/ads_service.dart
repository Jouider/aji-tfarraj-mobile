import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/features/ads/data/ads_gateway.dart';
import 'package:aji_tfarraj/features/ads/domain/ads_config.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;
import 'package:aji_tfarraj/features/tutorials/data/tutorials_repository.dart';

/// Quand une publicité a le droit de s'ouvrir, et laquelle.
///
/// Les règles sont ici plutôt que dans les écrans : un écran qui décide
/// lui-même finit par en montrer deux d'affilée.
class AdsService {
  AdsService({
    required AdsGateway gateway,
    required AdsConfig config,
    required SharedPreferences prefs,
    DateTime Function() clock = DateTime.now,
  })  : _gateway = gateway,
        _config = config,
        _prefs = prefs,
        _clock = clock;

  static const _lastInterstitialKey = 'ads_last_interstitial_at';

  final AdsGateway _gateway;
  final AdsConfig _config;
  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  bool _busy = false;

  AdsConfig get config => _config;

  /// L'interstitiel d'après-réservation.
  ///
  /// L'appelant attend d'abord [ReservationAds.delay] : la confirmation se lit
  /// avant que l'écran ne parte. Rend true si une pub a bien été montrée.
  Future<bool> showAfterReservation() async {
    final placement = _config.reservation;
    final unitId = _config.interstitialUnitId;

    if (!placement.enabled || unitId == null || _busy) return false;
    if (!_cooldownElapsed(placement.cooldown)) return false;

    _busy = true;
    try {
      final shown = await _gateway.showInterstitial(unitId);
      // Le délai ne court qu'à partir d'une pub réellement vue : un échec de
      // chargement ne doit pas consommer le créneau suivant.
      if (shown) {
        await _prefs.setString(
            _lastInterstitialKey, _clock().toIso8601String());
      }
      return shown;
    } finally {
      _busy = false;
    }
  }

  /// La vidéo récompensée, depuis l'écran fidélité.
  ///
  /// Rend true quand le membre est allé au bout. Les points arrivent ensuite,
  /// par le rappel signé que Google envoie au serveur — d'où le rafraîchissement
  /// différé côté écran.
  Future<bool> showRewarded({required int userId}) async {
    final unitId = _config.rewardedUnitId;

    if (!_config.rewarded.enabled || unitId == null || _busy) return false;

    _busy = true;
    try {
      return await _gateway.showRewarded(unitId, userId: userId.toString());
    } finally {
      _busy = false;
    }
  }

  bool _cooldownElapsed(Duration cooldown) {
    if (cooldown == Duration.zero) return true;

    final last = DateTime.tryParse(_prefs.getString(_lastInterstitialKey) ?? '');
    if (last == null) return true;

    return _clock().difference(last) >= cooldown;
  }
}

/// Ce que le serveur autorise, relu à chaque session avec le reste de
/// `app-config`.
final adsConfigProvider = FutureProvider<AdsConfig>(
  (ref) async =>
      AdsConfig.fromAppConfig(await ref.watch(appConfigJsonProvider.future)),
);

/// Le SDK. Remplacé par [SilentAdsGateway] dans les tests.
final adsGatewayProvider = Provider<AdsGateway>((ref) => AdMobGateway());

final adsServiceProvider = Provider<AdsService>((ref) {
  // Tant que la config n'est pas arrivée, rien n'est autorisé : c'est la
  // bonne valeur par défaut, pas un état d'attente à gérer.
  final config = ref.watch(adsConfigProvider).valueOrNull ?? AdsConfig.none;

  return AdsService(
    gateway: ref.watch(adsGatewayProvider),
    config: config,
    prefs: ref.watch(sharedPreferencesProvider),
  );
});
