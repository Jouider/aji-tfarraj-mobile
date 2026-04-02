/// Episode model — a single recording/filming session within a Show
class Episode {
  final int id;
  final String title;
  final String? displayTitle;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String city;
  final String? studio;
  final int capacity;
  final int reservedSeats;
  final int? rewardPoints;
  final bool isActive;

  Episode({
    required this.id,
    required this.title,
    this.displayTitle,
    required this.startsAt,
    this.endsAt,
    required this.city,
    this.studio,
    required this.capacity,
    required this.reservedSeats,
    this.rewardPoints,
    required this.isActive,
  });

  int get availableSeats => capacity - reservedSeats;

  bool get isSoldOut => availableSeats <= 0;

  int get effectiveRewardPoints => rewardPoints ?? 20;

  /// User-facing title: prefer display_title, fall back to title
  String get label => displayTitle ?? title;

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      displayTitle: json['display_title'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      city: json['city'] as String? ?? '',
      studio: json['studio'] as String?,
      capacity: json['capacity'] as int? ?? 0,
      reservedSeats: json['reserved_seats'] as int? ?? 0,
      rewardPoints: json['reward_points'] as int?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'display_title': displayTitle,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt?.toIso8601String(),
      'city': city,
      'studio': studio,
      'capacity': capacity,
      'reserved_seats': reservedSeats,
      'reward_points': rewardPoints,
      'is_active': isActive,
    };
  }

  @override
  String toString() => 'Episode(id: $id, title: $title, city: $city)';
}
