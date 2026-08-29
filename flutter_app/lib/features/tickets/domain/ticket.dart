import 'package:aji_tfarraj/features/shows/domain/show.dart';

/// Lightweight reservation data for ticket context (avoids circular import)
class TicketReservationInfo {
  final int id;
  final int showId;
  final int seats;
  final String status;
  final Show? show;

  TicketReservationInfo({
    required this.id,
    required this.showId,
    required this.seats,
    required this.status,
    this.show,
  });

  factory TicketReservationInfo.fromJson(Map<String, dynamic> json) {
    return TicketReservationInfo(
      id: json['id'] as int,
      showId: json['show_id'] as int,
      seats: json['seats'] as int,
      status: json['status'] as String,
      show: json['show'] != null
          ? Show.fromJson(json['show'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'show_id': showId,
      'seats': seats,
      'status': status,
      'show': show?.toJson(),
    };
  }
}

/// Ticket model matching backend API response
class Ticket {
  final int id;
  final int reservationId;
  final String ticketCode;
  final String qrToken;
  final DateTime? generatedAt;
  final DateTime? checkedInAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TicketReservationInfo? reservationInfo;

  Ticket({
    required this.id,
    required this.reservationId,
    required this.ticketCode,
    required this.qrToken,
    this.generatedAt,
    this.checkedInAt,
    this.createdAt,
    this.updatedAt,
    this.reservationInfo,
  });

  /// How long a ticket stays valid after the recording starts, when the backend
  /// gives us no explicit end time. A recording runs for a few hours and staff
  /// keep scanning latecomers throughout, so a ticket must NOT expire at its
  /// start time — doing that hid the QR from everyone arriving during the shoot.
  /// Mirrors the server-side rule in TicketController (ends_at, else +12h).
  static const Duration grace = Duration(hours: 12);

  /// Check if ticket has been used (checked in)
  bool get isCheckedIn => checkedInAt != null;

  /// Get show from reservation info (convenience getter)
  Show? get show => reservationInfo?.show;

  /// The moment this ticket stops being "upcoming".
  ///
  /// Uses the recording's end when known; `episodes.ends_at` is still NULL in
  /// production, so we fall back to start + [grace]. Null when the show has no
  /// dates at all.
  DateTime? get validUntil {
    final s = show;
    if (s == null) return null;

    final end = s.endsAt;
    if (end != null) return end;

    return s.startsAt?.add(grace);
  }

  /// Whether the ticket should still be shown as usable at [now].
  ///
  /// A ticket with no dates at all stays upcoming — never hidden — which is the
  /// safe side for someone standing at the door with a QR to scan.
  bool isUpcomingAt(DateTime now) {
    final until = validUntil;
    return until == null || !until.isBefore(now);
  }

  /// Get seats count from reservation info
  int get seats => reservationInfo?.seats ?? 1;

  /// Create Ticket from JSON (snake_case from API)
  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      reservationId: json['reservation_id'] as int,
      ticketCode: json['ticket_code'] as String,
      qrToken: json['qr_token'] as String,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : null,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      reservationInfo: json['reservation'] != null
          ? TicketReservationInfo.fromJson(json['reservation'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Create Ticket from JSON with reservation context
  /// Used when ticket is nested inside a reservation response
  factory Ticket.fromJsonWithReservationContext(
    Map<String, dynamic> ticketJson,
    Map<String, dynamic> reservationJson,
  ) {
    return Ticket(
      id: ticketJson['id'] as int,
      reservationId: ticketJson['reservation_id'] as int,
      ticketCode: ticketJson['ticket_code'] as String,
      qrToken: ticketJson['qr_token'] as String,
      generatedAt: ticketJson['generated_at'] != null
          ? DateTime.parse(ticketJson['generated_at'] as String)
          : null,
      checkedInAt: ticketJson['checked_in_at'] != null
          ? DateTime.parse(ticketJson['checked_in_at'] as String)
          : null,
      createdAt: ticketJson['created_at'] != null
          ? DateTime.parse(ticketJson['created_at'] as String)
          : null,
      updatedAt: ticketJson['updated_at'] != null
          ? DateTime.parse(ticketJson['updated_at'] as String)
          : null,
      reservationInfo: TicketReservationInfo.fromJson(reservationJson),
    );
  }

  /// Convert Ticket to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reservation_id': reservationId,
      'ticket_code': ticketCode,
      'qr_token': qrToken,
      'generated_at': generatedAt?.toIso8601String(),
      'checked_in_at': checkedInAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'reservation': reservationInfo?.toJson(),
    };
  }

  @override
  String toString() => 'Ticket(id: $id, ticketCode: $ticketCode)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ticket &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ticketCode == other.ticketCode;

  @override
  int get hashCode => id.hashCode ^ ticketCode.hashCode;
}
