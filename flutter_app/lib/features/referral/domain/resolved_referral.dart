/// A single episode (recording date) returned inside a resolved referral link.
class ReferralEpisode {
  final int id;
  final String? title;
  final String? titleAr;
  final DateTime startsAt;
  final int capacity;
  final int reservedSeats;

  ReferralEpisode({
    required this.id,
    this.title,
    this.titleAr,
    required this.startsAt,
    this.capacity = 0,
    this.reservedSeats = 0,
  });

  int get availableSeats => capacity - reservedSeats;
  bool get isSoldOut => availableSeats <= 0;

  factory ReferralEpisode.fromJson(Map<String, dynamic> json) {
    return ReferralEpisode(
      id: json['id'] as int,
      title: json['title'] as String?,
      titleAr: json['title_ar'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      capacity: json['capacity'] as int? ?? 0,
      reservedSeats: json['reserved_seats'] as int? ?? 0,
    );
  }
}

/// Result of resolving a magic referral link token (public endpoint)
class ResolvedReferral {
  final String referralCode;
  final ReferralReferrer referrer;
  final ResolvedReferralShow show;
  final List<ReferralEpisode> episodes;

  ResolvedReferral({
    required this.referralCode,
    required this.referrer,
    required this.show,
    this.episodes = const [],
  });

  factory ResolvedReferral.fromJson(Map<String, dynamic> json) {
    final rawEpisodes = json['episodes'] as List<dynamic>? ?? [];
    return ResolvedReferral(
      referralCode: json['referral_code'] as String,
      referrer:
          ReferralReferrer.fromJson(json['referrer'] as Map<String, dynamic>),
      show: ResolvedReferralShow.fromJson(json['show'] as Map<String, dynamic>),
      episodes: rawEpisodes
          .map((e) => ReferralEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReferralReferrer {
  final String name;
  final String? avatarUrl;

  ReferralReferrer({required this.name, this.avatarUrl});

  factory ReferralReferrer.fromJson(Map<String, dynamic> json) {
    return ReferralReferrer(
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class ResolvedReferralShow {
  final int id;
  final String title;
  final String? titleAr;
  final String? description;
  final String? descriptionAr;
  final String? imageUrl;
  final String? channel;
  final String city;
  final DateTime startsAt;
  final int capacity;
  final int reservedSeats;

  ResolvedReferralShow({
    required this.id,
    required this.title,
    this.titleAr,
    this.description,
    this.descriptionAr,
    this.imageUrl,
    this.channel,
    required this.city,
    required this.startsAt,
    this.capacity = 0,
    this.reservedSeats = 0,
  });

  int get availableSeats => capacity - reservedSeats;
  bool get isSoldOut => availableSeats <= 0;

  String localizedTitle(bool isAr) =>
      (isAr && titleAr != null && titleAr!.isNotEmpty) ? titleAr! : title;

  String? localizedDescription(bool isAr) =>
      (isAr && descriptionAr != null && descriptionAr!.isNotEmpty)
          ? descriptionAr
          : description;

  factory ResolvedReferralShow.fromJson(Map<String, dynamic> json) {
    return ResolvedReferralShow(
      id: json['id'] as int,
      title: json['title'] as String,
      titleAr: json['title_ar'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['description_ar'] as String?,
      imageUrl: json['image_url'] as String?,
      channel: json['channel'] as String?,
      city: json['city'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      capacity: json['capacity'] as int? ?? 0,
      reservedSeats: json['reserved_seats'] as int? ?? 0,
    );
  }
}
