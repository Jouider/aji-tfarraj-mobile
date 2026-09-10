/// The shuttle sheet: how many people are waiting at each drop-off point once
/// the recording is over.
///
/// Comes from `GET /api/staff/return-manifest?episode_id=X`. The door records
/// each answer one at a time ({@see TicketPreview}); this adds them up for
/// whoever runs the vehicles.
library;

/// A recording the manifest can be drawn up for.
class ManifestEpisode {
  final int id;
  final String? title;
  final String? showTitle;
  final DateTime? startsAt;
  final String? studio;
  final String? city;

  const ManifestEpisode({
    required this.id,
    this.title,
    this.showTitle,
    this.startsAt,
    this.studio,
    this.city,
  });

  /// What to call this recording on screen. Episodes are often untitled, in
  /// which case the show name is the only thing that identifies it.
  String get label {
    final t = title;
    if (t != null && t.isNotEmpty) return t;
    return showTitle ?? 'Tournage #$id';
  }

  factory ManifestEpisode.fromJson(Map<String, dynamic> json) =>
      ManifestEpisode(
        id: json['id'] as int,
        title: json['title'] as String?,
        showTitle: json['show_title'] as String? ??
            (json['show'] as Map<String, dynamic>?)?['title'] as String?,
        startsAt: json['starts_at'] is String
            ? DateTime.parse(json['starts_at'] as String).toLocal()
            : null,
        studio: json['studio'] as String?,
        city: json['city'] as String?,
      );
}

/// One passenger waiting at a stop. Names only — this sheet gets forwarded on,
/// and the scanner can already look a phone number up at the door.
class ManifestPassenger {
  final String name;
  final int seats;

  const ManifestPassenger({required this.name, this.seats = 1});

  factory ManifestPassenger.fromJson(Map<String, dynamic> json) =>
      ManifestPassenger(
        name: json['name'] as String? ?? '—',
        seats: json['seats'] as int? ?? 1,
      );
}

/// One stop, with everyone heading for it.
class ManifestPoint {
  final int id;
  final String name;
  final String? nameAr;
  final String? landmark;

  /// Whether this stop is on tonight's list. False means an admin retired it
  /// *after* people chose it — they are still waiting, so the sheet keeps them
  /// and flags the anomaly rather than hiding it.
  final bool served;

  /// Headcount. This is what the dispatcher sizes the vehicle from.
  final int people;

  /// How many bookings that headcount comes from.
  final int tickets;

  final List<ManifestPassenger> passengers;

  const ManifestPoint({
    required this.id,
    required this.name,
    this.nameAr,
    this.landmark,
    this.served = true,
    this.people = 0,
    this.tickets = 0,
    this.passengers = const [],
  });

  /// Localised label — falls back to French when no Arabic name is set.
  String localizedName(bool isAr) =>
      (isAr && nameAr != null && nameAr!.isNotEmpty) ? nameAr! : name;

  /// A stop nobody chose still belongs on the sheet: that is how the dispatcher
  /// knows not to send a vehicle, rather than guessing it was forgotten.
  bool get isEmpty => people == 0;

  factory ManifestPoint.fromJson(Map<String, dynamic> json) => ManifestPoint(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        nameAr: json['name_ar'] as String?,
        landmark: json['landmark'] as String?,
        served: json['served'] as bool? ?? true,
        people: json['people'] as int? ?? 0,
        tickets: json['tickets'] as int? ?? 0,
        passengers: (json['passengers'] as List<dynamic>? ?? const [])
            .map((e) => ManifestPassenger.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ReturnManifest {
  final ManifestEpisode episode;
  final String showTitle;
  final DateTime generatedAt;

  /// False means no stop is switched on for this recording, so no vehicle is
  /// running — worth saying out loud instead of showing an empty table.
  final bool hasShuttle;

  final int checkedInPeople;
  final int checkedInTickets;

  /// People who asked for a lift.
  final int riders;

  /// People who said they would make their own way home.
  final int ownMeans;

  final List<ManifestPoint> points;

  const ReturnManifest({
    required this.episode,
    this.showTitle = '',
    required this.generatedAt,
    this.hasShuttle = false,
    this.checkedInPeople = 0,
    this.checkedInTickets = 0,
    this.riders = 0,
    this.ownMeans = 0,
    this.points = const [],
  });

  /// Stops with at least one passenger, in the admin's order. The vehicles
  /// actually going somewhere.
  List<ManifestPoint> get servedTonight =>
      points.where((p) => p.people > 0).toList();

  /// Somebody chose a stop that has since been retired or dropped from this
  /// episode. They are still standing outside, so this needs to be visible.
  bool get hasOrphanedPassengers =>
      points.any((p) => !p.served && p.people > 0);

  factory ReturnManifest.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? const {};

    return ReturnManifest(
      episode: ManifestEpisode.fromJson(
          json['episode'] as Map<String, dynamic>? ?? const {'id': 0}),
      showTitle:
          (json['show'] as Map<String, dynamic>?)?['title'] as String? ?? '',
      generatedAt: json['generated_at'] is String
          ? DateTime.parse(json['generated_at'] as String).toLocal()
          : DateTime.now(),
      hasShuttle: json['has_shuttle'] as bool? ?? false,
      checkedInPeople: totals['checked_in_people'] as int? ?? 0,
      checkedInTickets: totals['checked_in_tickets'] as int? ?? 0,
      riders: totals['riders'] as int? ?? 0,
      ownMeans: totals['own_means'] as int? ?? 0,
      points: (json['points'] as List<dynamic>? ?? const [])
          .map((e) => ManifestPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
