import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';

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
  final Reservation? reservation;

  Ticket({
    required this.id,
    required this.reservationId,
    required this.ticketCode,
    required this.qrToken,
    this.generatedAt,
    this.checkedInAt,
    this.createdAt,
    this.updatedAt,
    this.reservation,
  });

  /// Check if ticket has been used (checked in)
  bool get isCheckedIn => checkedInAt != null;

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
      reservation: json['reservation'] != null
          ? Reservation.fromJson(json['reservation'] as Map<String, dynamic>)
          : null,
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
      'reservation': reservation?.toJson(),
    };
  }

  @override
  String toString() => 'Ticket(id: $id, ticketCode: $ticketCode)';
}
