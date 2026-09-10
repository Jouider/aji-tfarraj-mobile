import 'package:aji_tfarraj/features/staff/domain/return_point_option.dart';

export 'package:aji_tfarraj/features/staff/domain/return_point_option.dart';

// Models for on-site registration — the door flow where staff open a real
// account for someone who turned up without booking.

/// An episode door staff can register someone onto.
class OnSiteEpisode {
  final int id;
  final String? title;
  final DateTime? startsAt;
  final String? studio;
  final int? capacity;
  final int? reservedSeats;

  /// Stops the shuttle serves that night. **Empty means no shuttle**, and the
  /// door must not put the question at all.
  final List<ReturnPointOption> returnPoints;

  const OnSiteEpisode({
    required this.id,
    this.title,
    this.startsAt,
    this.studio,
    this.capacity,
    this.reservedSeats,
    this.returnPoints = const [],
  });

  /// Whether to ask a walk-in where they are heading afterwards.
  bool get asksReturnPoint => returnPoints.isNotEmpty;

  /// Seats still free, when the backend gave us both numbers.
  int? get availableSeats => (capacity != null && reservedSeats != null)
      ? capacity! - reservedSeats!
      : null;

  factory OnSiteEpisode.fromJson(Map<String, dynamic> json) => OnSiteEpisode(
        id: json['id'] as int,
        title: json['title'] as String?,
        startsAt: json['starts_at'] != null
            ? DateTime.parse(json['starts_at'] as String)
            : null,
        studio: json['studio'] as String?,
        capacity: json['capacity'] as int?,
        reservedSeats: json['reserved_seats'] as int?,
        returnPoints: (json['return_points'] as List<dynamic>? ?? const [])
            .map((e) => ReturnPointOption.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A show with the episodes currently open for on-site registration.
class OnSiteShow {
  final int id;
  final String title;
  final String? city;
  final List<OnSiteEpisode> episodes;

  const OnSiteShow({
    required this.id,
    required this.title,
    this.city,
    this.episodes = const [],
  });

  factory OnSiteShow.fromJson(Map<String, dynamic> json) => OnSiteShow(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        city: json['city'] as String?,
        episodes: (json['episodes'] as List<dynamic>? ?? [])
            .map((e) => OnSiteEpisode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A chargé public the attendee can be credited to.
class ChargePublicOption {
  final int id;
  final String name;
  final String? referralCode;

  const ChargePublicOption({
    required this.id,
    required this.name,
    this.referralCode,
  });

  factory ChargePublicOption.fromJson(Map<String, dynamic> json) =>
      ChargePublicOption(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        referralCode: json['referral_code'] as String?,
      );
}

/// What comes back after a successful registration.
///
/// [password] is the one and only time the clear password exists — the column
/// stores a hash — so the screen must show it before leaving.
class OnSiteRegistrationResult {
  final int userId;
  final String name;
  final String? avatarUrl;
  final String email;
  final String password;
  final bool emailGenerated;
  final int? rewardAmount;

  const OnSiteRegistrationResult({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.email,
    required this.password,
    required this.emailGenerated,
    this.rewardAmount,
  });

  factory OnSiteRegistrationResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final creds = json['credentials'] as Map<String, dynamic>? ?? const {};
    return OnSiteRegistrationResult(
      userId: user['id'] as int? ?? 0,
      name: user['name'] as String? ?? '',
      avatarUrl: user['avatar_url'] as String?,
      email: creds['email'] as String? ?? '',
      password: creds['password'] as String? ?? '',
      emailGenerated: creds['email_generated'] as bool? ?? false,
      rewardAmount: json['reward_amount'] as int?,
    );
  }
}

/// Whether the last step of the walk-in form is complete.
///
/// Named and pulled out of the screen because of the last clause: when a
/// shuttle runs, the drop-off question has to have been **put**, not merely
/// offered. A null stop means both "makes their own way" and "nobody asked",
/// so if the form can be submitted without an answer the two collapse into
/// one — the shuttle sheet under-counts and somebody is left at the studio.
bool onSiteLocationStepComplete({
  required String? cityName,
  required String? district,
  required bool asksReturnPoint,
  required bool returnPointAnswered,
}) {
  return cityName != null &&
      district != null &&
      (!asksReturnPoint || returnPointAnswered);
}
