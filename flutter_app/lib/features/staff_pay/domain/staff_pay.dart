/// La paie du staff : `GET /api/me/staff-pay`.
///
/// Trois postes payés par épisode — superviseur des chargés publics, chauffeur
/// de salle (un montant selon que l'émission est grande ou petite), équipe
/// technique (1 DH par personne entrée). Le serveur calcule tout ; l'app
/// affiche. Le retrait passe par Wafacash, sur le même solde que les gains de
/// chargé public.
library;

/// Un poste, sur une période.
class StaffPosition {
  const StaffPosition({
    required this.position,
    required this.startsOn,
    this.endsOn,
    required this.current,
  });

  /// `cp_supervisor` | `warm_up` | `tech`
  final String position;
  final DateTime startsOn;
  final DateTime? endsOn;
  final bool current;

  factory StaffPosition.fromJson(Map<String, dynamic> json) => StaffPosition(
        position: json['position'] as String? ?? '',
        startsOn: DateTime.tryParse(json['starts_on'] as String? ?? '') ??
            DateTime(2026, 10, 8),
        endsOn: DateTime.tryParse(json['ends_on'] as String? ?? ''),
        current: json['current'] as bool? ?? false,
      );
}

/// Un épisode payé, pour un poste.
class StaffPayLine {
  const StaffPayLine({
    required this.episodeId,
    required this.date,
    this.show,
    this.episode,
    required this.position,
    this.size,
    required this.entries,
    required this.amount,
    required this.pending,
  });

  final int episodeId;
  final DateTime date;
  final String? show;
  final String? episode;
  final String position;

  /// `big` | `small`, null tant que l'admin n'a pas choisi.
  final String? size;

  /// Personnes entrées (scans + walk-ins).
  final int entries;
  final int amount;

  /// Format de l'émission pas encore choisi : dû, pas encore chiffré.
  final bool pending;

  bool get isTech => position == 'tech';

  factory StaffPayLine.fromJson(Map<String, dynamic> json) => StaffPayLine(
        episodeId: (json['episode_id'] as num?)?.toInt() ?? 0,
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime(2026, 10, 8),
        show: json['show'] as String?,
        episode: json['episode'] as String?,
        position: json['position'] as String? ?? '',
        size: json['size'] as String?,
        entries: (json['entries'] as num?)?.toInt() ?? 0,
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        pending: json['pending'] as bool? ?? false,
      );
}

class StaffPayOverview {
  const StaffPayOverview({
    required this.positions,
    required this.total,
    required this.episodes,
    required this.pending,
    required this.available,
    required this.lines,
  });

  final List<StaffPosition> positions;

  /// Gagné sur les postes du staff, depuis le début.
  final int total;
  final int episodes;

  /// Épisodes dont l'émission n'a pas encore de format.
  final int pending;

  /// Ce qui se retire maintenant : paie du staff ET gains de chargé public.
  final int available;
  final List<StaffPayLine> lines;

  List<StaffPosition> get currentPositions =>
      positions.where((p) => p.current).toList();

  factory StaffPayOverview.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String key) => (json[key] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final balance = json['balance'] is Map
        ? Map<String, dynamic>.from(json['balance'] as Map)
        : const <String, dynamic>{};

    return StaffPayOverview(
      positions: list('positions').map(StaffPosition.fromJson).toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      episodes: (json['episodes'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      available: (balance['available'] as num?)?.toInt() ?? 0,
      lines: list('lines').map(StaffPayLine.fromJson).toList(),
    );
  }
}
