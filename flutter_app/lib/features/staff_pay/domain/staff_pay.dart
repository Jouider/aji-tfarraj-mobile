/// La paie du staff : `GET /api/me/staff-pay`.
///
/// Postes payés par épisode — superviseur des chargés publics, chauffeur de
/// salle, équipe technique (par personne entrée), inscription à la porte. Un
/// poste peut avoir un montant convenu avec la personne, et être limité à une
/// émission. Le serveur calcule tout, tarifs compris ; l'app affiche. Le retrait passe par Wafacash, sur le même solde que les gains de
/// chargé public.
library;

/// Un poste, sur une période.
class StaffPosition {
  const StaffPosition({
    required this.position,
    required this.startsOn,
    this.endsOn,
    required this.current,
    this.show,
    this.rate,
  });

  /// `cp_supervisor` | `warm_up` | `tech` | `door`
  final String position;
  final DateTime startsOn;
  final DateTime? endsOn;
  final bool current;

  /// L'émission pour laquelle la personne est recrutée ; null : toutes.
  final String? show;

  /// Le montant convenu avec la personne, en DH par épisode (par entrée pour
  /// l'équipe technique) ; null : le tarif standard.
  final int? rate;

  factory StaffPosition.fromJson(Map<String, dynamic> json) => StaffPosition(
        position: json['position'] as String? ?? '',
        startsOn: DateTime.tryParse(json['starts_on'] as String? ?? '') ??
            DateTime(2026, 10, 8),
        endsOn: DateTime.tryParse(json['ends_on'] as String? ?? ''),
        current: json['current'] as bool? ?? false,
        show: json['show'] as String?,
        rate: (json['rate'] as num?)?.toInt(),
      );
}

/// Les tarifs standard, tels que le serveur les envoie (`rates`). Les valeurs
/// par défaut ne servent que si la réponse ne les porte pas.
class StaffPayRates {
  const StaffPayRates({
    this.episode = const {
      'big': {'cp_supervisor': 300, 'warm_up': 200},
      'small': {'cp_supervisor': 200, 'warm_up': 200},
    },
    this.perEntry = 1,
    this.doorDiscountPercent = 20,
  });

  /// Par format (`big` | `small`), puis par poste, en DH par épisode.
  final Map<String, Map<String, int>> episode;
  final int perEntry;

  /// La remise « sur place » dont le poste à la porte touche une part.
  final int doorDiscountPercent;

  int? forEpisode(String size, String position) => episode[size]?[position];

  /// Ce que touche un poste, grande et petite émission — par entrée pour
  /// l'équipe technique. Le montant convenu avec la personne remplace les deux.
  (int?, int?) amountsFor(StaffPosition p) => switch (p.position) {
        'tech' => (p.rate ?? perEntry, p.rate ?? perEntry),
        'door' => (0, 0),
        _ => (
            p.rate ?? forEpisode('big', p.position),
            p.rate ?? forEpisode('small', p.position),
          ),
      };

  factory StaffPayRates.fromJson(Map<String, dynamic> json) {
    const defaults = StaffPayRates();
    final episode = <String, Map<String, int>>{};
    final raw = json['episode'];
    if (raw is Map) {
      raw.forEach((size, rates) {
        if (rates is Map) {
          episode['$size'] = {
            for (final e in rates.entries)
              if (e.value is num) '${e.key}': (e.value as num).toInt(),
          };
        }
      });
    }

    return StaffPayRates(
      episode: episode.isEmpty ? defaults.episode : episode,
      perEntry: (json['per_entry'] as num?)?.toInt() ?? defaults.perEntry,
      doorDiscountPercent: (json['door_discount_percent'] as num?)?.toInt() ??
          defaults.doorDiscountPercent,
    );
  }
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
    this.rates = const StaffPayRates(),
    required this.total,
    required this.episodes,
    required this.pending,
    required this.available,
    required this.lines,
  });

  final List<StaffPosition> positions;
  final StaffPayRates rates;

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
      rates: json['rates'] is Map
          ? StaffPayRates.fromJson(
              Map<String, dynamic>.from(json['rates'] as Map))
          : const StaffPayRates(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      episodes: (json['episodes'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      available: (balance['available'] as num?)?.toInt() ?? 0,
      lines: list('lines').map(StaffPayLine.fromJson).toList(),
    );
  }
}
