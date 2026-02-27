// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';

// ---------------------------------------------------------------------------
// The 7 statuses defined in the API contract, and the rules around each.
// ---------------------------------------------------------------------------

const _allStatuses = [
  'pending_review',
  'contacting',
  'approved',
  'rejected',
  'cancelled',
  'expired',
  'checked_in',
];

/// Statuses where a user is still allowed to cancel.
const _cancellableStatuses = ['pending_review', 'contacting'];

/// Statuses where cancellation is NOT allowed.
const _nonCancellableStatuses = [
  'approved',
  'rejected',
  'cancelled',
  'expired',
  'checked_in',
];

Map<String, dynamic> _reservationJson({
  required String status,
  Map<String, dynamic>? ticketJson,
  String? rejectionReason,
}) {
  return {
    'id': 42,
    'user_id': 1,
    'show_id': 5,
    'seats': 2,
    'status': status,
    'rejection_reason': rejectionReason,
    'expires_at': null,
    'created_at': '2026-02-01T10:00:00.000000Z',
    'updated_at': '2026-02-01T10:00:00.000000Z',
    'show': null,
    'ticket': ticketJson,
  };
}

Map<String, dynamic> _ticketJson() => {
      'id': 8,
      'reservation_id': 42,
      'ticket_code': 'AT-2026-000008',
      'qr_token': '550e8400-e29b-41d4-a716-446655440000',
      'generated_at': '2026-02-01T14:00:00.000000Z',
      'checked_in_at': null,
      'created_at': '2026-02-01T14:00:00.000000Z',
      'updated_at': '2026-02-01T14:00:00.000000Z',
    };

void main() {
  group('Approval flow — all statuses parse correctly', () {
    for (final status in _allStatuses) {
      test('status "$status" round-trips through fromJson', () {
        final r = Reservation.fromJson(_reservationJson(status: status));
        expect(r.status, status);
        expect(r.id, 42);
        expect(r.seats, 2);
      });
    }
  });

  group('Approval flow — cancellation eligibility', () {
    // Business rule: user can only cancel at pending_review or contacting.
    // The app checks this before showing the "Annuler" button.
    bool canCancel(String status) =>
        status == 'pending_review' || status == 'contacting';

    for (final status in _cancellableStatuses) {
      test('can cancel when status is "$status"', () {
        final r = Reservation.fromJson(_reservationJson(status: status));
        expect(canCancel(r.status), isTrue);
      });
    }

    for (final status in _nonCancellableStatuses) {
      test('cannot cancel when status is "$status"', () {
        final r = Reservation.fromJson(_reservationJson(status: status));
        expect(canCancel(r.status), isFalse);
      });
    }
  });

  group('Approval flow — ticket field', () {
    test('ticket is null for pending_review', () {
      final r = Reservation.fromJson(_reservationJson(status: 'pending_review'));
      expect(r.ticket, isNull);
    });

    test('ticket is null for contacting', () {
      final r = Reservation.fromJson(_reservationJson(status: 'contacting'));
      expect(r.ticket, isNull);
    });

    test('ticket is null for rejected', () {
      final r = Reservation.fromJson(_reservationJson(status: 'rejected'));
      expect(r.ticket, isNull);
    });

    test('ticket is null for cancelled', () {
      final r = Reservation.fromJson(_reservationJson(status: 'cancelled'));
      expect(r.ticket, isNull);
    });

    test('ticket is null for expired', () {
      final r = Reservation.fromJson(_reservationJson(status: 'expired'));
      expect(r.ticket, isNull);
    });

    test('ticket is present when status is approved', () {
      final r = Reservation.fromJson(_reservationJson(
        status: 'approved',
        ticketJson: _ticketJson(),
      ));
      expect(r.ticket, isNotNull);
      expect(r.ticket!.ticketCode, 'AT-2026-000008');
    });
  });
}
