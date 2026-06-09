// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/tickets/domain/ticket.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';

// ---------------------------------------------------------------------------
// Rule: A ticket is only generated (and visible) when a reservation is
// in the `approved` state.  Any other status → no ticket.
// ---------------------------------------------------------------------------

Map<String, dynamic> _reservationJson({
  required String status,
  Map<String, dynamic>? ticketJson,
}) {
  return {
    'id': 15,
    'user_id': 1,
    'show_id': 1,
    'seats': 2,
    'status': status,
    'rejection_reason': null,
    'expires_at': null,
    'created_at': '2026-01-30T12:00:00.000000Z',
    'updated_at': '2026-01-30T14:00:00.000000Z',
    'show': {
      'id': 1,
      'title': 'Lalla Laaroussa',
      'description': null,
      'city': 'Casablanca',
      'channel': '2M',
      'studio': 'Studio 2M Ain Sebaa',
      'starts_at': '2026-02-15T20:00:00.000000Z',
      'capacity': 150,
      'reserved_seats': 47,
      'reward_points': 50,
      'is_active': true,
      'image_url': null,
      'created_at': '2026-01-15T09:00:00.000000Z',
      'updated_at': '2026-01-30T14:00:00.000000Z',
    },
    'ticket': ticketJson,
  };
}

Map<String, dynamic> _ticketJson({String? checkedInAt}) => {
      'id': 8,
      'reservation_id': 15,
      'ticket_code': 'AT-2026-000008',
      'qr_token': '550e8400-e29b-41d4-a716-446655440000',
      'generated_at': '2026-01-30T14:00:00.000000Z',
      'checked_in_at': checkedInAt,
      'created_at': '2026-01-30T14:00:00.000000Z',
      'updated_at': '2026-01-30T14:00:00.000000Z',
    };

void main() {
  group('Ticket generation lock — locked statuses', () {
    const lockedStatuses = [
      'pending_review',
      'contacting',
      'rejected',
      'cancelled',
      'expired',
    ];

    for (final status in lockedStatuses) {
      test('ticket is null for status "$status"', () {
        // Backend does not send a ticket for these statuses.
        final r = Reservation.fromJson(_reservationJson(status: status));
        expect(r.ticket, isNull,
            reason: 'No ticket should be available when status is "$status"');
      });
    }
  });

  group('Ticket generation lock — unlocked on approved', () {
    test('ticket is non-null when reservation is approved', () {
      final r = Reservation.fromJson(_reservationJson(
        status: 'approved',
        ticketJson: _ticketJson(),
      ));
      expect(r.ticket, isNotNull);
    });

    test('ticket carries the correct code and QR token', () {
      final r = Reservation.fromJson(_reservationJson(
        status: 'approved',
        ticketJson: _ticketJson(),
      ));
      expect(r.ticket!.ticketCode, 'AT-2026-000008');
      expect(r.ticket!.qrToken, '550e8400-e29b-41d4-a716-446655440000');
    });

    test('ticket includes show context via reservationInfo', () {
      final r = Reservation.fromJson(_reservationJson(
        status: 'approved',
        ticketJson: _ticketJson(),
      ));
      expect(r.ticket!.show, isNotNull);
      expect(r.ticket!.show!.title, 'Lalla Laaroussa');
    });

    test('ticket seats are inherited from reservation', () {
      final r = Reservation.fromJson(_reservationJson(
        status: 'approved',
        ticketJson: _ticketJson(),
      ));
      // ReservationInfo.seats should match the reservation seats
      expect(r.ticket!.seats, r.seats);
    });
  });

  group('Ticket — direct fromJson parsing', () {
    test('Ticket.fromJson parses all fields correctly', () {
      final t = Ticket.fromJson({
        'id': 8,
        'reservation_id': 15,
        'ticket_code': 'AT-2026-000008',
        'qr_token': '550e8400-e29b-41d4-a716-446655440000',
        'generated_at': '2026-01-30T14:00:00.000000Z',
        'checked_in_at': null,
        'created_at': '2026-01-30T14:00:00.000000Z',
        'updated_at': '2026-01-30T14:00:00.000000Z',
        'reservation': null,
      });

      expect(t.id, 8);
      expect(t.ticketCode, 'AT-2026-000008');
      expect(t.qrToken, '550e8400-e29b-41d4-a716-446655440000');
      expect(t.generatedAt, isNotNull);
      expect(t.isCheckedIn, isFalse);
    });
  });
}
