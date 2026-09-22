import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Le SDK AdMob, derrière une porte.
///
/// Tout ce qui touche au plugin passe par ici, et par rien d'autre : un test
/// Flutter n'a pas de canal de plateforme, et sans cette séparation aucun
/// écran qui affiche une pub ne serait testable.
abstract class AdsGateway {
  /// Recueille le consentement puis démarre le SDK. Idempotent.
  Future<void> initialize();

  /// Charge et montre un interstitiel. Rend false si rien n'a pu être montré
  /// — réseau, inventaire vide, unité inconnue : dans tous ces cas l'écran
  /// continue comme si de rien n'était.
  Future<bool> showInterstitial(String unitId);

  /// Charge et montre une vidéo récompensée. Rend true si le membre est allé
  /// au bout. Les points, eux, ne sont crédités que par le rappel signé que
  /// Google envoie au serveur — jamais par ce booléen.
  Future<bool> showRewarded(String unitId, {required String userId});
}

/// L'implémentation réelle.
class AdMobGateway implements AdsGateway {
  AdMobGateway();

  Future<void>? _starting;

  /// Au-delà, on renonce : une pub qui arrive après que le membre est passé à
  /// autre chose est pire que pas de pub.
  static const _loadTimeout = Duration(seconds: 8);

  @override
  Future<void> initialize() => _starting ??= _start();

  Future<void> _start() async {
    // Le consentement d'abord : au Maroc le formulaire ne s'affiche pas, mais
    // il s'affichera pour un membre en Europe, et le SDK doit le savoir avant
    // de demander la première pub.
    await _gatherConsent();
    await MobileAds.instance.initialize();
  }

  Future<void> _gatherConsent() async {
    final gathered = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((error) {
            if (error != null && kDebugMode) {
              debugPrint('[Ads] formulaire de consentement : ${error.message}');
            }
          });
        } finally {
          if (!gathered.isCompleted) gathered.complete();
        }
      },
      (error) {
        if (kDebugMode) debugPrint('[Ads] consentement : ${error.message}');
        if (!gathered.isCompleted) gathered.complete();
      },
    );

    // Un formulaire qui ne répond pas ne bloque pas l'app pour autant.
    await gathered.future.timeout(const Duration(seconds: 10),
        onTimeout: () => null);
  }

  @override
  Future<bool> showInterstitial(String unitId) async {
    await initialize();

    final shown = Completer<bool>();

    await InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _complete(shown, false);
            },
          );
          ad.show();
          _complete(shown, true);
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) debugPrint('[Ads] interstitiel : ${error.message}');
          _complete(shown, false);
        },
      ),
    );

    return shown.future
        .timeout(_loadTimeout, onTimeout: () => false);
  }

  @override
  Future<bool> showRewarded(String unitId, {required String userId}) async {
    await initialize();

    final finished = Completer<bool>();
    var earned = false;

    await RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) async {
          // C'est cet identifiant que le serveur retrouvera dans le rappel
          // signé : sans lui, personne ne sait à qui créditer les points.
          await ad.setServerSideOptions(
            ServerSideVerificationOptions(userId: userId),
          );

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _complete(finished, earned);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _complete(finished, false);
            },
          );

          ad.show(onUserEarnedReward: (ad, reward) => earned = true);
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) debugPrint('[Ads] vidéo : ${error.message}');
          _complete(finished, false);
        },
      ),
    );

    // La vidéo se regarde jusqu'au bout : le délai ne couvre que le
    // chargement, pas la lecture, d'où l'attente longue.
    return finished.future
        .timeout(const Duration(minutes: 5), onTimeout: () => earned);
  }

  void _complete(Completer<bool> completer, bool value) {
    if (!completer.isCompleted) completer.complete(value);
  }
}

/// Aucune publicité : l'implémentation des tests, et le filet quand le serveur
/// n'annonce rien.
class SilentAdsGateway implements AdsGateway {
  const SilentAdsGateway();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> showInterstitial(String unitId) async => false;

  @override
  Future<bool> showRewarded(String unitId, {required String userId}) async =>
      false;
}
