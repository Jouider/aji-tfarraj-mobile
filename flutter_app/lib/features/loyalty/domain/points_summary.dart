/// A single points history entry
class PointsEntry {
  final int id;
  final String type;
  final int points;
  final Map<String, dynamic>? meta;
  final DateTime createdAt;

  const PointsEntry({
    required this.id,
    required this.type,
    required this.points,
    this.meta,
    required this.createdAt,
  });

  /// Defensive factory from JSON map
  factory PointsEntry.fromJson(Map<String, dynamic> json) {
    return PointsEntry(
      id: _parseInt(json['id']),
      type: (json['type'] as String?) ?? 'unknown',
      points: _parseInt(json['points']),
      meta: json['meta'] is Map<String, dynamic>
          ? json['meta'] as Map<String, dynamic>
          : null,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'points': points,
      'meta': meta,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Whether the entry represents earned (positive) points
  bool get isPositive => points > 0;

  /// Formatted points string (e.g. "+20" or "-10")
  String get formattedPoints => isPositive ? '+$points' : '$points';

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

/// Ce que la vidéo récompensée rapporte, et ce qu'il en reste pour aujourd'hui.
///
/// Servi par `GET /api/me/points → ad_reward`. C'est le serveur qui compte :
/// le téléphone ne fait qu'afficher, et ne décide jamais du crédit.
class AdRewardStatus {
  const AdRewardStatus({
    required this.enabled,
    required this.points,
    required this.dailyCap,
    required this.remainingToday,
  });

  /// Rien à proposer : publicité éteinte, ou serveur d'avant la fonction.
  static const off = AdRewardStatus(
    enabled: false,
    points: 0,
    dailyCap: 0,
    remainingToday: 0,
  );

  final bool enabled;

  /// Les points annoncés par vidéo.
  final int points;

  final int dailyCap;

  /// Ce qu'il reste de vidéos créditables aujourd'hui.
  final int remainingToday;

  /// Le bouton ne s'affiche que là : éteint, sans points ou quota épuisé, il
  /// n'y a rien à proposer, et proposer pour refuser ensuite est pire.
  bool get canWatch => enabled && points > 0 && remainingToday > 0;

  factory AdRewardStatus.fromJson(dynamic json) {
    if (json is! Map) return off;

    return AdRewardStatus(
      enabled: json['enabled'] == true,
      points: PointsEntry._parseInt(json['points']),
      dailyCap: PointsEntry._parseInt(json['daily_cap']),
      remainingToday: PointsEntry._parseInt(json['remaining_today']),
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'points': points,
        'daily_cap': dailyCap,
        'remaining_today': remainingToday,
      };
}

/// Points summary containing balance and history
class PointsSummary {
  final int balance;
  final List<PointsEntry> history;

  /// La vidéo récompensée, telle que le serveur l'autorise à cet instant.
  final AdRewardStatus adReward;

  const PointsSummary({
    required this.balance,
    required this.history,
    this.adReward = AdRewardStatus.off,
  });

  /// Empty / default summary
  static const empty = PointsSummary(balance: 0, history: []);

  /// Defensive factory from JSON map.
  /// Supports both direct object and wrapped `{ data: {...} }` shapes.
  factory PointsSummary.fromJson(Map<String, dynamic> json) {
    // Unwrap if the response is wrapped in a "data" key
    final Map<String, dynamic> data =
        json.containsKey('data') && json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : json;

    final rawHistory = data['history'];
    final List<PointsEntry> history;
    if (rawHistory is List) {
      history = rawHistory
          .whereType<Map<String, dynamic>>()
          .map((e) => PointsEntry.fromJson(e))
          .toList();
    } else {
      history = [];
    }

    return PointsSummary(
      balance: _parseInt(data['balance']),
      history: history,
      adReward: AdRewardStatus.fromJson(data['ad_reward']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'history': history.map((e) => e.toJson()).toList(),
      'ad_reward': adReward.toJson(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
