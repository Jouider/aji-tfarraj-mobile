import 'package:aji_tfarraj/features/shows/domain/show.dart';
import 'package:aji_tfarraj/features/tickets/domain/ticket.dart';

/// Reservation model matching backend API response
class Reservation {
  final int id;
  final int userId;
  final int showId;
  final int? episodeId;
  final int seats;
  final String status;
  final String? rejectionReason;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Show? show;
  final Ticket? ticket;

  /// La liste d'attente du jour J, quand le plateau est complet : `waiting`
  /// (on appelle si une place se libère) ou `coming` (la personne a dit
  /// qu'elle peut venir, pas encore approuvée). Null sinon, et sur un vieux
  /// serveur. Le `status` reste « En attente » dans les deux cas.
  final String? waitlist;

  Reservation({
    required this.id,
    required this.userId,
    required this.showId,
    this.episodeId,
    required this.seats,
    required this.status,
    this.rejectionReason,
    this.expiresAt,
    required this.createdAt,
    this.updatedAt,
    this.show,
    this.ticket,
    this.waitlist,
  });

  /// Sur la liste d'attente, et seulement tant que la demande est en attente.
  bool get onWaitlist =>
      (waitlist == 'waiting' || waitlist == 'coming') &&
      (status == 'pending_review' || status == 'contacting');

  bool get waitlistComing => onWaitlist && waitlist == 'coming';

  /// Create Reservation from JSON (snake_case from API)
  factory Reservation.fromJson(Map<String, dynamic> json) {
    // Parse show first so we can use it for ticket context
    final show = json['show'] != null
        ? Show.fromJson(json['show'] as Map<String, dynamic>)
        : null;

    // Build ticket with reservation context if present
    Ticket? ticket;
    if (json['ticket'] != null) {
      final ticketJson = json['ticket'] as Map<String, dynamic>;
      // Create a reservation context for the ticket
      final reservationContext = {
        'id': json['id'],
        'show_id': json['show_id'],
        'seats': json['seats'],
        'status': json['status'],
        'show': json['show'],
      };
      ticket =
          Ticket.fromJsonWithReservationContext(ticketJson, reservationContext);
    }

    return Reservation(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      showId: json['show_id'] as int,
      episodeId: json['episode_id'] as int?,
      seats: json['seats'] as int? ?? 1,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      show: show,
      ticket: ticket,
      waitlist: json['waitlist'] as String?,
    );
  }

  /// Convert Reservation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'show_id': showId,
      'episode_id': episodeId,
      'seats': seats,
      'status': status,
      'rejection_reason': rejectionReason,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'show': show?.toJson(),
      'ticket': ticket?.toJson(),
      'waitlist': waitlist,
    };
  }

  @override
  String toString() => 'Reservation(id: $id, showId: $showId, status: $status)';
}
