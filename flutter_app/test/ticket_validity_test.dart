import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';
import 'package:aji_tfarraj/features/tickets/domain/ticket.dart';

/// Regression tests for the blocking bug reported in issue #16: the ticket
/// disappeared from the screen the moment the episode's start time passed, so
/// anyone arriving during the recording had no QR to scan and staff were stuck
/// at the door (14 people on the 13:00 episode of 28/08).
///
/// The rule: a ticket stays usable until the END of the recording — ends_at
/// when known, otherwise starts_at + 12h, mirroring the server's TicketController.

Ticket _ticketWith({DateTime? startsAt, DateTime? endsAt, bool withShow = true}) {
  return Ticket(
    id: 1,
    reservationId: 1,
    ticketCode: 'TCK-1',
    qrToken: 'qr-token',
    reservationInfo: withShow
        ? TicketReservationInfo(
            id: 1,
            showId: 1,
            seats: 1,
            status: 'approved',
            show: Show(
              id: 1,
              title: 'Planet Foot',
              isActive: true,
              city: 'Casablanca',
              capacity: 180,
              reservedSeats: 55,
              startsAt: startsAt,
              endsAt: endsAt,
            ),
          )
        : null,
  );
}

void main() {
  // The exact scenario from the issue: episode starts at 13:00.
  final start = DateTime(2026, 8, 28, 13, 0);

  group('Ticket stays usable during the recording (issue #16)', () {
    test('one second after the start time, the ticket is STILL upcoming', () {
      // This is the precise moment the old code hid the ticket.
      final t = _ticketWith(startsAt: start);

      expect(t.isUpcomingAt(start.add(const Duration(seconds: 1))), isTrue);
    });

    test('the blocked arrivals (14:42 / 14:53) still see their ticket', () {
      final t = _ticketWith(startsAt: start);

      expect(t.isUpcomingAt(DateTime(2026, 8, 28, 14, 42)), isTrue);
      expect(t.isUpcomingAt(DateTime(2026, 8, 28, 14, 53)), isTrue);
    });

    test('before the show it is upcoming, as it always was', () {
      final t = _ticketWith(startsAt: start);

      expect(t.isUpcomingAt(DateTime(2026, 8, 28, 12, 0)), isTrue);
    });

    test('it does expire once the 12h grace has fully elapsed', () {
      final t = _ticketWith(startsAt: start);

      expect(t.isUpcomingAt(start.add(const Duration(hours: 12, minutes: 1))),
          isFalse);
      // Next day: firmly in the past.
      expect(t.isUpcomingAt(DateTime(2026, 8, 29, 13, 0)), isFalse);
    });

    test('validUntil falls back to start + 12h when ends_at is NULL (prod)', () {
      final t = _ticketWith(startsAt: start);

      expect(t.validUntil, start.add(Ticket.grace));
    });
  });

  group('Explicit ends_at wins over the fallback', () {
    test('a real end time is used instead of the 12h grace', () {
      final end = DateTime(2026, 8, 28, 16, 30);
      final t = _ticketWith(startsAt: start, endsAt: end);

      expect(t.validUntil, end);
      expect(t.isUpcomingAt(DateTime(2026, 8, 28, 16, 0)), isTrue);
      expect(t.isUpcomingAt(DateTime(2026, 8, 28, 16, 31)), isFalse);
    });
  });

  group('Tickets are never lost when dates are missing', () {
    test('a show with no dates at all stays upcoming (never hidden)', () {
      final t = _ticketWith(startsAt: null);

      expect(t.validUntil, isNull);
      expect(t.isUpcomingAt(DateTime(2026, 8, 28, 14, 53)), isTrue);
    });

    test('a ticket with no show at all stays upcoming', () {
      final t = _ticketWith(withShow: false);

      expect(t.validUntil, isNull);
      expect(t.isUpcomingAt(DateTime(2026, 8, 28, 14, 53)), isTrue);
    });

    test('ends_at without starts_at is honoured and does not crash', () {
      final end = DateTime(2026, 8, 28, 16, 30);
      final t = _ticketWith(startsAt: null, endsAt: end);

      expect(t.validUntil, end);
      expect(t.isUpcomingAt(DateTime(2026, 8, 28, 16, 0)), isTrue);
      expect(t.isUpcomingAt(DateTime(2026, 8, 28, 17, 0)), isFalse);
    });
  });

  group('Show model parses ends_at', () {
    test('ends_at is read from the API payload', () {
      final show = Show.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'Planet Foot',
        'city': 'Casablanca',
        'starts_at': '2026-08-28T13:00:00',
        'ends_at': '2026-08-28T16:30:00',
      });

      expect(show.endsAt, DateTime(2026, 8, 28, 16, 30));
    });

    test('a missing ends_at stays null (current production payload)', () {
      final show = Show.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'Planet Foot',
        'city': 'Casablanca',
        'starts_at': '2026-08-28T13:00:00',
      });

      expect(show.endsAt, isNull);
      expect(show.startsAt, DateTime(2026, 8, 28, 13, 0));
    });
  });
}
