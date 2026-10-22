/// La roue de la chance, telle que le serveur la décrit.
///
/// Servie par `GET /api/me/wheel`. Le serveur tire chaque résultat ; l'app ne
/// fait que dessiner les cases et arrêter la roue sur celle qu'il désigne.
library;

/// `points` | `retry` | `reward`
enum WheelOutcome {
  points,
  retry,
  reward;

  static WheelOutcome parse(Object? raw) => switch (raw) {
        'points' => WheelOutcome.points,
        'reward' => WheelOutcome.reward,
        _ => WheelOutcome.retry,
      };
}

/// Une case de la roue, dans l'ordre où elle est dessinée.
class WheelSlice {
  const WheelSlice({required this.type, this.points = 0});

  final WheelOutcome type;
  final int points;

  factory WheelSlice.fromJson(Map<String, dynamic> json) => WheelSlice(
        type: WheelOutcome.parse(json['type']),
        points: _int(json['points']),
      );
}

/// La récompense rare de la roue.
class WheelReward {
  const WheelReward({
    required this.id,
    required this.title,
    this.titleAr,
    this.imageUrl,
    this.availableToday = true,
  });

  final int id;
  final String title;
  final String? titleAr;
  final String? imageUrl;

  /// Le stock du jour n'est pas épuisé.
  final bool availableToday;

  String titleFor({required bool arabic}) =>
      arabic && (titleAr?.isNotEmpty ?? false) ? titleAr! : title;

  factory WheelReward.fromJson(Map<String, dynamic> json) => WheelReward(
        id: _int(json['id']),
        title: json['title']?.toString() ?? '',
        titleAr: json['title_ar']?.toString(),
        imageUrl: json['image_url']?.toString(),
        availableToday: json['available_today'] != false,
      );
}

class WheelStatus {
  const WheelStatus({
    required this.enabled,
    required this.dailySpins,
    required this.spinsLeft,
    required this.slices,
    required this.pointsBalance,
    this.adSpinsLeft = 0,
    this.adSpinsEnabled = false,
    int? freeSpins,
    this.jackpot,
    this.resetsAt,
  }) : freeSpins = freeSpins ?? dailySpins;

  final bool enabled;
  final int dailySpins;

  /// Les essais à tourner tout de suite, sans vidéo.
  final int spinsLeft;

  /// Les essais du jour qui restent à débloquer, une vidéo chacun.
  final int adSpinsLeft;

  /// Après les essais gratuits, chaque essai se débloque avec une vidéo.
  final bool adSpinsEnabled;

  /// Les essais gratuits par jour (tous, quand il n'y a pas de vidéo).
  final int freeSpins;

  final List<WheelSlice> slices;
  final WheelReward? jackpot;
  final int pointsBalance;

  /// Minuit à Casablanca, là où les essais reviennent.
  final DateTime? resetsAt;

  bool _resetBy(DateTime now) => resetsAt != null && !now.isBefore(resetsAt!);

  /// Les essais à l'heure qu'il est : passé minuit, ils sont revenus, même
  /// si l'écran n'a pas encore relu le serveur.
  int spinsLeftAt(DateTime now) => _resetBy(now) ? freeSpins : spinsLeft;

  /// Les essais à débloquer avec une vidéo, à l'heure qu'il est.
  int adSpinsLeftAt(DateTime now) => _resetBy(now)
      ? (adSpinsEnabled ? dailySpins - freeSpins : 0)
      : adSpinsLeft;

  /// Plus d'essai tout de suite, mais une vidéo en rendrait un.
  bool videoUnlocksSpinAt(DateTime now) =>
      spinsLeftAt(now) == 0 && adSpinsLeftAt(now) > 0;

  /// Une roue qu'on peut montrer : ouverte, et avec de quoi dessiner.
  bool get playable => enabled && slices.length >= 2;

  /// Après un tour : les essais et le solde que le serveur a renvoyés.
  WheelStatus after(SpinResult r) => WheelStatus(
        enabled: enabled,
        dailySpins: dailySpins,
        spinsLeft: r.spinsLeft,
        adSpinsLeft: r.adSpinsLeft ?? adSpinsLeft,
        adSpinsEnabled: adSpinsEnabled,
        freeSpins: freeSpins,
        slices: slices,
        pointsBalance: r.pointsBalance,
        jackpot: jackpot,
        resetsAt: resetsAt,
      );

  factory WheelStatus.fromJson(Map<String, dynamic> json) {
    final daily = _int(json['daily_spins'], 3);
    return WheelStatus(
      enabled: json['enabled'] == true,
      dailySpins: daily,
      spinsLeft: _int(json['spins_left']),
      adSpinsLeft: _int(json['ad_spins_left']),
      adSpinsEnabled: json['ad_spins_enabled'] == true,
      freeSpins: _int(json['free_spins'], daily),
      slices: _list(json['slices']).map(WheelSlice.fromJson).toList(),
      jackpot: json['jackpot'] is Map<String, dynamic>
          ? WheelReward.fromJson(json['jackpot'] as Map<String, dynamic>)
          : null,
      pointsBalance: _int(json['points_balance']),
      resetsAt: DateTime.tryParse(json['resets_at']?.toString() ?? ''),
    );
  }
}

/// Ce que le serveur a tiré.
class SpinResult {
  const SpinResult({
    required this.outcome,
    required this.points,
    required this.slice,
    required this.spinsLeft,
    required this.pointsBalance,
    this.adSpinsLeft,
    this.reward,
  });

  final WheelOutcome outcome;
  final int points;

  /// L'index de la case où arrêter la roue.
  final int slice;
  final int spinsLeft;

  /// Les essais encore à débloquer avec une vidéo. Null pour un serveur qui
  /// ne le dit pas encore : l'état d'avant reste alors juste.
  final int? adSpinsLeft;

  final int pointsBalance;
  final WheelReward? reward;

  /// Plus d'essai tout de suite, mais une vidéo en rendrait un.
  bool get videoUnlocksSpin => spinsLeft == 0 && (adSpinsLeft ?? 0) > 0;

  factory SpinResult.fromJson(Map<String, dynamic> json) => SpinResult(
        outcome: WheelOutcome.parse(json['outcome']),
        points: _int(json['points']),
        slice: _int(json['slice']),
        spinsLeft: _int(json['spins_left']),
        adSpinsLeft: json['ad_spins_left'] == null
            ? null
            : _int(json['ad_spins_left']),
        pointsBalance: _int(json['points_balance']),
        reward: json['reward'] is Map<String, dynamic>
            ? WheelReward.fromJson(json['reward'] as Map<String, dynamic>)
            : null,
      );
}

int _int(Object? v, [int fallback = 0]) => switch (v) {
      int i => i,
      num n => n.toInt(),
      String s => int.tryParse(s) ?? fallback,
      _ => fallback,
    };

List<Map<String, dynamic>> _list(Object? v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];
