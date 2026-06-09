import 'package:aji_tfarraj/features/shows/domain/episode.dart';

/// Show model matching backend API response
class Show {
  final int id;
  final String title;
  final String? titleAr;
  final String? description;
  final String? descriptionAr;
  final String? category;
  final String? channel;
  final String? channelAr;
  final String? dateFr;
  final String? dateAr;
  final String? imageUrl;
  final String? videoUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Episode data
  final Episode? nextEpisode;
  final List<Episode> episodes;
  final int totalEpisodes;
  final int upcomingEpisodesCount;

  // Backward-compat top-level fields (mirror next_episode values from API)
  final String city;
  final String? studio;
  final DateTime? startsAt;
  final int capacity;
  final int reservedSeats;
  final int? rewardPoints;

  Show({
    required this.id,
    required this.title,
    this.titleAr,
    this.description,
    this.descriptionAr,
    this.category,
    this.channel,
    this.channelAr,
    this.dateFr,
    this.dateAr,
    this.imageUrl,
    this.videoUrl,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.nextEpisode,
    this.episodes = const [],
    this.totalEpisodes = 0,
    this.upcomingEpisodesCount = 0,
    required this.city,
    this.studio,
    this.startsAt,
    required this.capacity,
    required this.reservedSeats,
    this.rewardPoints,
  });

  /// Whether the show has upcoming episodes to reserve
  bool get hasUpcomingEpisodes => nextEpisode != null;

  /// Available seats count (from backward-compat fields)
  int get availableSeats => capacity - reservedSeats;

  /// Points awarded on check-in. Falls back to 20 if not set by backend.
  int get effectiveRewardPoints => rewardPoints ?? 20;

  /// Check if show is sold out
  bool get isSoldOut => availableSeats <= 0;

  /// Localized title — falls back to French if AR is null
  String localizedTitle(bool isAr) =>
      (isAr && titleAr != null && titleAr!.isNotEmpty) ? titleAr! : title;

  /// Localized description — falls back to French if AR is null
  String? localizedDescription(bool isAr) =>
      (isAr && descriptionAr != null && descriptionAr!.isNotEmpty)
          ? descriptionAr
          : description;

  /// Localized channel name — falls back to French if AR is null
  String? localizedChannel(bool isAr) =>
      (isAr && channelAr != null && channelAr!.isNotEmpty)
          ? channelAr
          : channel;

  /// Localized date string preformatted by backend.
  /// Falls back to dateFr if Arabic is null, then null if both absent.
  String? localizedDate(bool isAr) =>
      (isAr && dateAr != null) ? dateAr : dateFr;

  /// Create Show from JSON (snake_case from API)
  factory Show.fromJson(Map<String, dynamic> json) {
    return Show(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      titleAr: json['title_ar'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['description_ar'] as String?,
      category: json['category'] as String?,
      channel: json['channel'] as String?,
      channelAr: json['channel_ar'] as String?,
      dateFr: json['date_fr'] as String?,
      dateAr: json['date_ar'] as String?,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      // Episode data
      nextEpisode: json['next_episode'] != null
          ? Episode.fromJson(json['next_episode'] as Map<String, dynamic>)
          : null,
      episodes: json['episodes'] != null
          ? (json['episodes'] as List)
              .map((e) => Episode.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      totalEpisodes: json['total_episodes'] as int? ?? 0,
      upcomingEpisodesCount: json['upcoming_episodes_count'] as int? ?? 0,
      // Backward-compat top-level fields
      city: json['city'] as String? ?? '',
      studio: json['studio'] as String?,
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      capacity: json['capacity'] as int? ?? 0,
      reservedSeats: json['reserved_seats'] as int? ?? 0,
      rewardPoints: json['reward_points'] as int?,
    );
  }

  /// Convert Show to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_ar': titleAr,
      'description': description,
      'description_ar': descriptionAr,
      'category': category,
      'channel': channel,
      'channel_ar': channelAr,
      'date_fr': dateFr,
      'date_ar': dateAr,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'next_episode': nextEpisode?.toJson(),
      'episodes': episodes.map((e) => e.toJson()).toList(),
      'total_episodes': totalEpisodes,
      'upcoming_episodes_count': upcomingEpisodesCount,
      'city': city,
      'studio': studio,
      'starts_at': startsAt?.toIso8601String(),
      'capacity': capacity,
      'reserved_seats': reservedSeats,
      'reward_points': rewardPoints,
    };
  }

  @override
  String toString() => 'Show(id: $id, title: $title, city: $city)';
}
