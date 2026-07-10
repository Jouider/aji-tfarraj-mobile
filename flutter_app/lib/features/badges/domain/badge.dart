import 'dart:ui';

/// Gamification badges returned by `GET /api/auth/me` under `badges`, and by
/// `GET /api/me/referrals` (the `level` object, same shape as [charge_public]).
///
/// The backend provides bilingual labels + a hex `color` and an `emoji` per
/// tier, so the app never hardcodes tier visuals or labels.

/// Parse a `#RRGGBB` hex string into a [Color] (null-safe).
Color? _parseHex(String? hex) {
  if (hex == null) return null;
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

/// A tiered badge with a level and a progress count (attendance / charge-public).
class LevelBadge {
  final String key;
  final int level;
  final String labelFr;
  final String labelAr;
  final String? colorHex;
  final String? emoji;

  /// Current metric value (episodes attended, or distinct attendees brought).
  final int count;

  /// Threshold of the next tier — null when already at the top tier.
  final int? nextLevelAt;

  const LevelBadge({
    required this.key,
    required this.level,
    required this.labelFr,
    required this.labelAr,
    this.colorHex,
    this.emoji,
    this.count = 0,
    this.nextLevelAt,
  });

  String localizedLabel(bool isAr) => isAr ? labelAr : labelFr;

  Color? get color => _parseHex(colorHex);

  bool get isMax => nextLevelAt == null;

  /// How many more units to reach the next tier (0 when maxed).
  int get remaining =>
      nextLevelAt == null ? 0 : (nextLevelAt! - count).clamp(0, nextLevelAt!);

  /// Progress within the current tier segment, 0..1.
  ///
  /// Uses the tier floor from [_tierMins] (stable thresholds) when known, so the
  /// bar reflects progress inside the current tier rather than from zero.
  double get progress {
    if (nextLevelAt == null) return 1.0;
    final floor = _tierMins[key] ?? 0;
    final span = nextLevelAt! - floor;
    if (span <= 0) return 1.0;
    return ((count - floor) / span).clamp(0.0, 1.0);
  }

  factory LevelBadge.fromJson(Map<String, dynamic> j) => LevelBadge(
        key: j['key'] as String? ?? '',
        level: (j['level'] as num?)?.toInt() ?? 0,
        labelFr: j['label_fr'] as String? ?? '',
        labelAr: j['label_ar'] as String? ?? '',
        colorHex: j['color'] as String?,
        emoji: j['emoji'] as String?,
        count: (j['count'] as num?)?.toInt() ?? 0,
        nextLevelAt: (j['next_level_at'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'level': level,
        'label_fr': labelFr,
        'label_ar': labelAr,
        'color': colorHex,
        'emoji': emoji,
        'count': count,
        'next_level_at': nextLevelAt,
      };
}

/// Flat staff badge (no level/count).
class StaffBadge {
  final String key;
  final String labelFr;
  final String labelAr;
  final String? colorHex;
  final String? emoji;

  const StaffBadge({
    required this.key,
    required this.labelFr,
    required this.labelAr,
    this.colorHex,
    this.emoji,
  });

  String localizedLabel(bool isAr) => isAr ? labelAr : labelFr;
  Color? get color => _parseHex(colorHex);

  factory StaffBadge.fromJson(Map<String, dynamic> j) => StaffBadge(
        key: j['key'] as String? ?? 'staff',
        labelFr: j['label_fr'] as String? ?? '',
        labelAr: j['label_ar'] as String? ?? '',
        colorHex: j['color'] as String?,
        emoji: j['emoji'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'label_fr': labelFr,
        'label_ar': labelAr,
        'color': colorHex,
        'emoji': emoji,
      };
}

/// All badges applicable to a user (from `/api/auth/me`).
class UserBadges {
  /// Always present (episodes attended).
  final LevelBadge? attendance;

  /// Present when the account is a charge public.
  final LevelBadge? chargePublic;

  /// Present for staff accounts.
  final StaffBadge? staff;

  const UserBadges({this.attendance, this.chargePublic, this.staff});

  factory UserBadges.fromJson(Map<String, dynamic> j) => UserBadges(
        attendance: j['attendance'] is Map<String, dynamic>
            ? LevelBadge.fromJson(j['attendance'] as Map<String, dynamic>)
            : null,
        chargePublic: j['charge_public'] is Map<String, dynamic>
            ? LevelBadge.fromJson(j['charge_public'] as Map<String, dynamic>)
            : null,
        staff: j['staff'] is Map<String, dynamic>
            ? StaffBadge.fromJson(j['staff'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'attendance': attendance?.toJson(),
        'charge_public': chargePublic?.toJson(),
        'staff': staff?.toJson(),
      };
}

/// Stable tier floors (min count) keyed by badge `key`, mirroring
/// backend `config/badges.php`. Used only to render an in-tier progress bar;
/// labels/colors/emojis still come from the API.
const Map<String, int> _tierMins = {
  // attendance
  'nouveau': 0, 'bronze': 1, 'argent': 6, 'or': 21, 'platine': 51, 'diamant': 81,
  // charge public
  'n1': 0, 'n2': 11, 'n3': 51, 'n4': 101, 'n5': 201,
};
