/// "Présents": everyone the door let in for one recording, and whether they
/// left before the end.
///
/// Comes from `GET /api/staff/attendees`. Leaving costs that evening's reward —
/// the attendee's points, and the pay of the charge public who brought them —
/// whatever the reason. Only an exclusion is held against them afterwards.
library;

/// Why someone left before the end.
enum DepartureReason {
  left('left'),
  unwell('unwell'),
  excluded('excluded'),
  other('other'),

  /// A reason this build does not know. Shown as-is, never picked.
  unknown('');

  const DepartureReason(this.key);

  final String key;

  /// The four the door can pick from, in the order they are offered.
  static const choices = [left, unwell, excluded, other];

  static DepartureReason fromKey(String? key) => values.firstWhere(
        (r) => r != unknown && r.key == key,
        orElse: () => unknown,
      );

  /// "Autre" says nothing on its own: the note is the reason.
  bool get needsNote => this == other;
}

class Departure {
  final DateTime at;
  final DepartureReason reason;
  final String? note;
  final String? recordedBy;

  const Departure({
    required this.at,
    required this.reason,
    this.note,
    this.recordedBy,
  });

  bool get isExclusion => reason == DepartureReason.excluded;

  /// Null when there is no departure — or one this build cannot read, which
  /// must never hide the fact that the person is still in the room.
  static Departure? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final at = DateTime.tryParse(json['at'] as String? ?? '');
    if (at == null) return null;
    return Departure(
      at: at.toLocal(),
      reason: DepartureReason.fromKey(json['reason'] as String?),
      note: json['note'] as String?,
      recordedBy: json['recorded_by'] as String?,
    );
  }
}

/// A member with a ticket, or a phoneless walk-in brought by a charge public.
enum AttendeeKind {
  reservation('reservation'),
  walkIn('walk_in');

  const AttendeeKind(this.key);

  final String key;

  static AttendeeKind fromKey(String? key) =>
      key == 'walk_in' ? walkIn : reservation;
}

class Attendee {
  final AttendeeKind kind;
  final int id;
  final String name;
  final String? photoUrl;
  final String? ticketCode;
  final DateTime? checkedInAt;

  /// Who brought them, when a charge public did.
  final String? chargePublic;

  /// False for walk-ins: no account, so nothing to remember them by next time.
  final bool hasAccount;

  final Departure? departure;

  /// Exclusions from earlier recordings.
  final int pastExclusions;
  final DateTime? lastExclusionAt;

  const Attendee({
    required this.kind,
    required this.id,
    required this.name,
    this.photoUrl,
    this.ticketCode,
    this.checkedInAt,
    this.chargePublic,
    this.hasAccount = true,
    this.departure,
    this.pastExclusions = 0,
    this.lastExclusionAt,
  });

  bool get hasLeft => departure != null;

  bool get wasExcludedBefore => pastExclusions > 0;

  /// Same person, whatever changed about them.
  bool sameAs(Attendee other) => kind == other.kind && id == other.id;

  factory Attendee.fromJson(Map<String, dynamic> json) => Attendee(
        kind: AttendeeKind.fromKey(json['kind'] as String?),
        id: json['id'] as int,
        name: json['name'] as String? ?? '—',
        photoUrl: json['photo_url'] as String?,
        ticketCode: json['ticket_code'] as String?,
        checkedInAt:
            DateTime.tryParse(json['checked_in_at'] as String? ?? '')?.toLocal(),
        chargePublic: json['charge_public'] as String?,
        hasAccount: json['has_account'] as bool? ?? true,
        departure: Departure.fromJson(json['departure']),
        pastExclusions: json['past_exclusions'] as int? ?? 0,
        lastExclusionAt: DateTime.tryParse(
                json['last_exclusion_at'] as String? ?? '')
            ?.toLocal(),
      );
}

class AttendeeList {
  final String showTitle;
  final String? episodeTitle;
  final DateTime? startsAt;
  final List<Attendee> attendees;

  const AttendeeList({
    required this.showTitle,
    this.episodeTitle,
    this.startsAt,
    this.attendees = const [],
  });

  int get presentCount => attendees.where((a) => !a.hasLeft).length;

  int get leftCount => attendees.where((a) => a.hasLeft).length;

  /// Part of a name — any case, with or without accents, in any order — or a
  /// ticket code. An empty query is everyone.
  List<Attendee> search(String query) {
    final words = foldForSearch(query)
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return attendees;

    final compact = words.join();
    return attendees.where((a) {
      final name = foldForSearch(a.name);
      final code = foldForSearch(a.ticketCode ?? '').replaceAll(' ', '');
      return words.every(name.contains) ||
          (code.isNotEmpty && code.contains(compact));
    }).toList();
  }

  /// The list with one row replaced — after a departure is recorded or undone,
  /// without reloading everyone.
  AttendeeList replacing(Attendee updated) => AttendeeList(
        showTitle: showTitle,
        episodeTitle: episodeTitle,
        startsAt: startsAt,
        attendees: [
          for (final a in attendees) a.sameAs(updated) ? updated : a,
        ],
      );

  factory AttendeeList.fromJson(Map<String, dynamic> json) {
    final episode = json['episode'] as Map<String, dynamic>? ?? const {};
    return AttendeeList(
      showTitle: episode['show_title'] as String? ?? '',
      episodeTitle: episode['title'] as String?,
      startsAt:
          DateTime.tryParse(episode['starts_at'] as String? ?? '')?.toLocal(),
      attendees: (json['attendees'] as List<dynamic>? ?? const [])
          .map((e) => Attendee.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i',
  'ô': 'o', 'ö': 'o', 'ó': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
  'ç': 'c', 'ÿ': 'y', 'ñ': 'n',
};

/// Lower-case, accents dropped: "Hélène" and "helene" are the same search.
String foldForSearch(String text) {
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final char in lower.split('')) {
    out.write(_accents[char] ?? char);
  }
  return out.toString().replaceAll('œ', 'oe').replaceAll('æ', 'ae');
}
