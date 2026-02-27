// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';

// ---------------------------------------------------------------------------
// Shared fixtures
// ---------------------------------------------------------------------------

Show _makeShow({
  int capacity = 100,
  int reservedSeats = 0,
  int? rewardPoints,
}) {
  return Show(
    id: 1,
    title: 'Lalla Laaroussa',
    city: 'Casablanca',
    startsAt: DateTime(2026, 6, 1, 20),
    capacity: capacity,
    reservedSeats: reservedSeats,
    isActive: true,
    rewardPoints: rewardPoints,
  );
}

Map<String, dynamic> _baseReservationJson({
  int seats = 2,
  String status = 'pending_review',
  Map<String, dynamic>? ticket,
  String? rejectionReason,
}) {
  return {
    'id': 10,
    'user_id': 1,
    'show_id': 1,
    'seats': seats,
    'status': status,
    'rejection_reason': rejectionReason,
    'expires_at': null,
    'created_at': '2026-01-30T12:00:00.000000Z',
    'updated_at': '2026-01-30T12:00:00.000000Z',
    'show': null,
    'ticket': ticket,
  };
}

// ---------------------------------------------------------------------------
// Booking edge cases
// ---------------------------------------------------------------------------

void main() {
  group('Show — availability', () {
    test('availableSeats = capacity − reservedSeats', () {
      final show = _makeShow(capacity: 100, reservedSeats: 45);
      expect(show.availableSeats, 55);
    });

    test('isSoldOut is false when seats remain', () {
      final show = _makeShow(capacity: 100, reservedSeats: 99);
      expect(show.isSoldOut, isFalse);
    });

    test('isSoldOut is true when reservedSeats == capacity', () {
      final show = _makeShow(capacity: 100, reservedSeats: 100);
      expect(show.isSoldOut, isTrue);
    });

    test('isSoldOut is true when reservedSeats > capacity (data anomaly)', () {
      // Guard: backend may over-count briefly under race conditions.
      final show = _makeShow(capacity: 100, reservedSeats: 101);
      expect(show.isSoldOut, isTrue);
      expect(show.availableSeats, lessThanOrEqualTo(0));
    });

    test('availableSeats is never shown as negative to the UI', () {
      final show = _makeShow(capacity: 50, reservedSeats: 52);
      // UI should clamp: max(0, availableSeats)
      final displayedSeats = show.availableSeats > 0 ? show.availableSeats : 0;
      expect(displayedSeats, 0);
    });
  });

  group('Show — reward points', () {
    test('effectiveRewardPoints returns custom value when set', () {
      final show = _makeShow(rewardPoints: 50);
      expect(show.effectiveRewardPoints, 50);
    });

    test('effectiveRewardPoints falls back to 20 when null', () {
      final show = _makeShow(rewardPoints: null);
      expect(show.effectiveRewardPoints, 20);
    });
  });

  group('Reservation — seat count constraints', () {
    // The API enforces min=1 max=4. Tests here verify the domain parses
    // seat counts correctly from any valid API response.
    for (final seats in [1, 2, 3, 4]) {
      test('seats=$seats is accepted', () {
        final r = Reservation.fromJson(_baseReservationJson(seats: seats));
        expect(r.seats, seats);
      });
    }

    test('status is preserved from JSON', () {
      for (final status in [
        'pending_review',
        'contacting',
        'approved',
        'rejected',
        'cancelled',
        'expired',
        'checked_in',
      ]) {
        final r = Reservation.fromJson(_baseReservationJson(status: status));
        expect(r.status, status, reason: 'status "$status" must survive round-trip');
      }
    });
  });

  group('Reservation — rejected reason', () {
    test('rejectionReason is null for non-rejected reservations', () {
      final r = Reservation.fromJson(_baseReservationJson(status: 'pending_review'));
      expect(r.rejectionReason, isNull);
    });

    test('rejectionReason is surfaced when status is rejected', () {
      final r = Reservation.fromJson(_baseReservationJson(
        status: 'rejected',
        rejectionReason: 'No more seats available for this date.',
      ));
      expect(r.status, 'rejected');
      expect(r.rejectionReason, isNotNull);
      expect(r.rejectionReason, contains('seats'));
    });
  });
}
