import 'package:flutter/foundation.dart';

/// Ce que le serveur autorise comme publicité, et à quelles conditions.
///
/// Servi par `GET /api/app-config → ads`, plateforme comprise : l'app ne reçoit
/// que ses propres unités. Tout est éteint par défaut — un serveur muet, une
/// vieille réponse en cache, une clé manquante, et il ne se passe rien.
@immutable
class AdsConfig {
  const AdsConfig({
    this.interstitialUnitId,
    this.rewardedUnitId,
    this.reservation = const ReservationAds.off(),
    this.rewarded = const RewardedAds.off(),
  });

  static const none = AdsConfig();

  /// L'unité interstitielle (après une réservation), ou null.
  final String? interstitialUnitId;

  /// L'unité de la vidéo récompensée (écran fidélité), ou null.
  final String? rewardedUnitId;

  final ReservationAds reservation;
  final RewardedAds rewarded;

  bool get isOff => !reservation.enabled && !rewarded.enabled;

  factory AdsConfig.fromAppConfig(Object? json) {
    if (json is! Map) return none;
    final ads = json['ads'];
    if (ads is! Map || ads['enabled'] != true) return none;

    final interstitial = _unit(ads['interstitial_unit_id']);
    final rewardedUnit = _unit(ads['rewarded_unit_id']);

    final reservation = ads['reservation'];
    final rewarded = ads['rewarded'];

    return AdsConfig(
      interstitialUnitId: interstitial,
      rewardedUnitId: rewardedUnit,
      // Un emplacement sans unité reste fermé : rien à demander au réseau.
      reservation: interstitial == null || reservation is! Map
          ? const ReservationAds.off()
          : ReservationAds(
              enabled: reservation['enabled'] == true,
              cooldown: Duration(
                  minutes: _int(reservation['cooldown_minutes'], fallback: 30)),
            ),
      rewarded: rewardedUnit == null || rewarded is! Map
          ? const RewardedAds.off()
          : RewardedAds(
              enabled: rewarded['enabled'] == true,
              points: _int(rewarded['points']),
              dailyCap: _int(rewarded['daily_cap']),
            ),
    );
  }

  static String? _unit(Object? value) {
    final unit = value is String ? value.trim() : '';
    return unit.isEmpty ? null : unit;
  }

  static int _int(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

/// L'interstitiel qui s'intercale entre « Réserver » et la confirmation.
///
/// La réservation est enregistrée avant qu'elle ne s'ouvre : la place est
/// acquise quoi qu'il arrive ensuite, y compris si la personne ferme l'app
/// pendant la pub.
@immutable
class ReservationAds {
  const ReservationAds({
    required this.enabled,
    required this.cooldown,
  });

  const ReservationAds.off()
      : enabled = false,
        cooldown = Duration.zero;

  final bool enabled;

  /// Deux réservations rapprochées ne donnent qu'une pub.
  final Duration cooldown;
}

/// La vidéo qu'on regarde pour des points, sur l'écran fidélité. Toujours un
/// choix : le règlement AdMob interdit de l'imposer, et les points ne valent
/// quelque chose que si on les gagne en venant au tournage.
@immutable
class RewardedAds {
  const RewardedAds({
    required this.enabled,
    required this.points,
    required this.dailyCap,
  });

  const RewardedAds.off()
      : enabled = false,
        points = 0,
        dailyCap = 0;

  final bool enabled;

  /// Les points annoncés par vidéo. Le serveur reste seul juge au crédit.
  final int points;

  /// Le nombre de vidéos créditées par jour et par membre.
  final int dailyCap;
}
