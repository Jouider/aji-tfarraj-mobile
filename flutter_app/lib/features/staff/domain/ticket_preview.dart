/// What the scanner sees after scanning, *before* admitting anyone.
///
/// Comes from `POST /api/staff/ticket/lookup`, which has no side effects — so
/// scanning to look is free, and the scanner can check the face against the
/// photo and fix a bad one before letting the person through.
enum TicketPreviewStatus {
  /// Validating will succeed.
  canCheckIn,

  /// The ticket has already been used.
  alreadyCheckedIn,

  /// The reservation was never approved.
  notApproved,

  /// Right ticket, wrong day — see [TicketPreview.reason].
  wrongDate,

  /// A status this build does not know about. Treated as blocking: admitting
  /// someone on a rule we cannot read would be worse than asking staff to look.
  unknown;

  static TicketPreviewStatus fromString(String? value) => switch (value) {
        'can_check_in' => TicketPreviewStatus.canCheckIn,
        'already_checked_in' => TicketPreviewStatus.alreadyCheckedIn,
        'not_approved' => TicketPreviewStatus.notApproved,
        'wrong_date' => TicketPreviewStatus.wrongDate,
        _ => TicketPreviewStatus.unknown,
      };
}

/// Why a wrong-date ticket was refused. The three cases are different
/// conversations at the door, so the app must be able to tell them apart.
enum WrongDateReason {
  /// The recording already happened.
  past,

  /// The recording is on a later date.
  future,

  /// The episode has no date at all — an admin data problem, not the
  /// attendee's fault.
  undated,

  unknown;

  static WrongDateReason fromString(String? value) => switch (value) {
        'past' => WrongDateReason.past,
        'future' => WrongDateReason.future,
        'undated' => WrongDateReason.undated,
        _ => WrongDateReason.unknown,
      };
}

/// A drop-off point the shuttle serves for this recording.
class ReturnPointOption {
  final int id;
  final String name;
  final String? nameAr;
  final String? landmark;

  const ReturnPointOption({
    required this.id,
    required this.name,
    this.nameAr,
    this.landmark,
  });

  /// Localised label — falls back to French when no Arabic name is set.
  String localizedName(bool isAr) =>
      (isAr && nameAr != null && nameAr!.isNotEmpty) ? nameAr! : name;

  factory ReturnPointOption.fromJson(Map<String, dynamic> json) =>
      ReturnPointOption(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        nameAr: json['name_ar'] as String?,
        landmark: json['landmark'] as String?,
      );
}

class TicketPreview {
  final TicketPreviewStatus status;
  final WrongDateReason? reason;
  final String ticketCode;
  final DateTime? checkedInAt;

  // Attendee
  final int? attendeeId;
  final String attendeeName;
  final String? attendeeAvatarUrl;

  /// An admin froze this photo, so the door must not offer to replace it.
  final bool avatarLocked;
  final String? attendeePhone;
  final bool isMinor;

  // Reservation
  final int? reservationId;
  final int seats;

  /// Stops the shuttle actually serves tonight. **Empty means there is no
  /// shuttle for this recording**, and the door must not ask the question.
  final List<ReturnPointOption> returnPoints;

  /// What this person already answered, if the question was put on an earlier
  /// scan — so the scanner does not ask twice.
  final int? chosenReturnPointId;

  // Episode / show
  final int? episodeId;
  final String? episodeTitle;
  final DateTime? episodeStartsAt;
  final String? studio;
  final String showTitle;

  const TicketPreview({
    required this.status,
    this.reason,
    required this.ticketCode,
    this.checkedInAt,
    this.attendeeId,
    required this.attendeeName,
    this.attendeeAvatarUrl,
    this.avatarLocked = false,
    this.attendeePhone,
    this.isMinor = false,
    this.reservationId,
    this.seats = 1,
    this.returnPoints = const [],
    this.chosenReturnPointId,
    this.episodeId,
    this.episodeTitle,
    this.episodeStartsAt,
    this.studio,
    this.showTitle = '',
  });

  /// Whether the scanner may validate this entry.
  bool get canAdmit => status == TicketPreviewStatus.canCheckIn;

  /// Whether to ask where they want to be dropped. No served stops means no
  /// shuttle tonight, so the question would be meaningless.
  bool get asksReturnPoint => returnPoints.isNotEmpty;

  /// A copy carrying a freshly recorded drop-off choice.
  TicketPreview withReturnPoint(int? pointId) => TicketPreview(
        status: status,
        reason: reason,
        ticketCode: ticketCode,
        checkedInAt: checkedInAt,
        attendeeId: attendeeId,
        attendeeName: attendeeName,
        attendeeAvatarUrl: attendeeAvatarUrl,
        avatarLocked: avatarLocked,
        attendeePhone: attendeePhone,
        isMinor: isMinor,
        reservationId: reservationId,
        seats: seats,
        returnPoints: returnPoints,
        chosenReturnPointId: pointId,
        episodeId: episodeId,
        episodeTitle: episodeTitle,
        episodeStartsAt: episodeStartsAt,
        studio: studio,
        showTitle: showTitle,
      );

  /// Whether the door may replace this person's photo. A locked avatar or a
  /// missing account leaves nothing to change.
  bool get canReplacePhoto => attendeeId != null && !avatarLocked;

  /// A copy carrying a freshly uploaded photo, so the preview updates without
  /// re-scanning the ticket.
  TicketPreview withAvatarUrl(String url) => TicketPreview(
        status: status,
        reason: reason,
        ticketCode: ticketCode,
        checkedInAt: checkedInAt,
        attendeeId: attendeeId,
        attendeeName: attendeeName,
        attendeeAvatarUrl: url,
        avatarLocked: avatarLocked,
        attendeePhone: attendeePhone,
        isMinor: isMinor,
        reservationId: reservationId,
        seats: seats,
        returnPoints: returnPoints,
        chosenReturnPointId: chosenReturnPointId,
        episodeId: episodeId,
        episodeTitle: episodeTitle,
        episodeStartsAt: episodeStartsAt,
        studio: studio,
        showTitle: showTitle,
      );

  factory TicketPreview.fromJson(Map<String, dynamic> json) {
    final attendee = json['attendee'] as Map<String, dynamic>? ?? const {};
    final reservation = json['reservation'] as Map<String, dynamic>? ?? const {};
    final episode = json['episode'] as Map<String, dynamic>? ?? const {};
    final show = json['show'] as Map<String, dynamic>? ?? const {};

    DateTime? parse(Object? v) =>
        v is String ? DateTime.parse(v).toLocal() : null;

    return TicketPreview(
      status: TicketPreviewStatus.fromString(json['status'] as String?),
      reason: json['reason'] != null
          ? WrongDateReason.fromString(json['reason'] as String?)
          : null,
      ticketCode: json['ticket_code'] as String? ?? '',
      checkedInAt: parse(json['checked_in_at']),
      attendeeId: attendee['id'] as int?,
      attendeeName: attendee['name'] as String? ?? '',
      attendeeAvatarUrl: attendee['avatar_url'] as String?,
      avatarLocked: attendee['avatar_locked'] as bool? ?? false,
      attendeePhone: attendee['phone'] as String?,
      isMinor: attendee['is_minor'] as bool? ?? false,
      reservationId: reservation['id'] as int?,
      seats: reservation['seats'] as int? ?? 1,
      returnPoints: (json['return_points'] as List<dynamic>? ?? [])
          .map((e) => ReturnPointOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      chosenReturnPointId:
          (reservation['return_point'] as Map<String, dynamic>?)?['id'] as int?,
      episodeId: episode['id'] as int?,
      episodeTitle: episode['title'] as String?,
      episodeStartsAt: parse(episode['starts_at']),
      studio: episode['studio'] as String?,
      showTitle: show['title'] as String? ?? '',
    );
  }
}
