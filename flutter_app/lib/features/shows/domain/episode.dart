/// Episode model — a single recording/filming session within a Show
class Episode {
  final int id;
  final String title;
  final String? displayTitle;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String city;
  final String? studio;
  final int capacity;
  final int reservedSeats;
  final int? rewardPoints;
  final bool isActive;

  // Localized fields (null → fallback to French value)
  final String? dateFr;
  final String? dateAr;
  final String? cityAr;
  final String? studioAr;

  Episode({
    required this.id,
    required this.title,
    this.displayTitle,
    this.startsAt,
    this.endsAt,
    required this.city,
    this.studio,
    required this.capacity,
    required this.reservedSeats,
    this.rewardPoints,
    required this.isActive,
    this.dateFr,
    this.dateAr,
    this.cityAr,
    this.studioAr,
  });

  int get availableSeats => capacity - reservedSeats;

  bool get isSoldOut => availableSeats <= 0;

  int get effectiveRewardPoints => rewardPoints ?? 20;

  /// User-facing title: prefer display_title, fall back to title
  String get label => displayTitle ?? title;

  /// True when the episode has a confirmed date.
  /// The real signal is starts_at being non-null. date_fr/date_ar are optional
  /// pre-formatted display strings that the backend may or may not provide.
  bool get hasConfirmedDate => startsAt != null;

  /// Localized date string — preformatted by backend.
  /// Returns null when not available (caller should fall back to formatting startsAt).
  String? localizedDate(bool isAr) =>
      (isAr && dateAr != null) ? dateAr : dateFr;

  /// Localized city name — falls back to French if Arabic is null.
  String localizedCity(bool isAr) =>
      (isAr && cityAr != null && cityAr!.isNotEmpty) ? cityAr! : city;

  /// Localized studio name — falls back to French if Arabic is null.
  String? localizedStudio(bool isAr) =>
      isAr ? (studioAr ?? studio) : studio;

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      displayTitle: json['display_title'] as String?,
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      city: json['city'] as String? ?? '',
      studio: json['studio'] as String?,
      capacity: json['capacity'] as int? ?? 0,
      reservedSeats: json['reserved_seats'] as int? ?? 0,
      rewardPoints: json['reward_points'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      dateFr: json['date_fr'] as String?,
      dateAr: json['date_ar'] as String?,
      cityAr: json['city_ar'] as String?,
      studioAr: json['studio_ar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'display_title': displayTitle,
      'starts_at': startsAt?.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'city': city,
      'studio': studio,
      'capacity': capacity,
      'reserved_seats': reservedSeats,
      'reward_points': rewardPoints,
      'is_active': isActive,
      'date_fr': dateFr,
      'date_ar': dateAr,
      'city_ar': cityAr,
      'studio_ar': studioAr,
    };
  }

  @override
  String toString() => 'Episode(id: $id, title: $title, city: $city)';
}
