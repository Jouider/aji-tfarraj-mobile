// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/tickets/domain/ticket.dart';
import 'package:aji_tfarraj/features/loyalty/domain/points_summary.dart';

// ---------------------------------------------------------------------------
// Rule: A ticket can only be checked in once.
//
// Prevention is enforced by the backend (409 Conflict on second scan), but
// the client must correctly:
//   1. Reflect the checked-in state when `checked_in_at` is set.
//   2. Show the "UTILISÉ" overlay and dim the QR code.
//   3. Fire `checkin_success` analytics only once per session.
//   4. Not award duplicate points (immutable ledger — enforced backend side,
//      verified here via PointsSummary idempotency on client parse).
// ---------------------------------------------------------------------------

Map<String, dynamic> _ticketJson({String? checkedInAt}) => {
      'id': 8,
      'reservation_id': 15,
      'ticket_code': 'AT-2026-000008',
      'qr_token': '550e8400-e29b-41d4-a716-446655440000',
      'generated_at': '2026-01-30T14:00:00.000000Z',
      'checked_in_at': checkedInAt,
      'created_at': '2026-01-30T14:00:00.000000Z',
      'updated_at': '2026-01-30T14:00:00.000000Z',
      'reservation': null,
    };

void main() {
  group('Double check-in prevention — isCheckedIn flag', () {
    test('isCheckedIn is false when checked_in_at is null (not yet scanned)', () {
      final t = Ticket.fromJson(_ticketJson(checkedInAt: null));
      expect(t.isCheckedIn, isFalse);
    });

    test('isCheckedIn is true when checked_in_at is set', () {
      final t = Ticket.fromJson(
        _ticketJson(checkedInAt: '2026-02-15T19:45:00.000000Z'),
      );
      expect(t.isCheckedIn, isTrue);
    });

    test('checkedInAt is parsed as UTC DateTime', () {
      final t = Ticket.fromJson(
        _ticketJson(checkedInAt: '2026-02-15T19:45:00.000000Z'),
      );
      expect(t.checkedInAt, isNotNull);
      expect(t.checkedInAt!.isUtc, isTrue);
    });

    test('two tickets with same code are equal (deduplication in UI list)', () {
      final t1 = Ticket.fromJson(_ticketJson());
      final t2 = Ticket.fromJson(_ticketJson());
      // Ticket equality is by id + ticketCode — prevents duplicate list entries
      expect(t1, equals(t2));
    });

    test('ticket code is preserved exactly (needed for manual verification)', () {
      final t = Ticket.fromJson(_ticketJson());
      expect(t.ticketCode, 'AT-2026-000008');
    });

    test('QR token is preserved exactly (scanned by staff app)', () {
      final t = Ticket.fromJson(_ticketJson());
      expect(t.qrToken, '550e8400-e29b-41d4-a716-446655440000');
    });
  });

  group('Double check-in prevention — points ledger idempotency', () {
    // The backend ensures points are only awarded once per reservation.
    // On the client side we verify that PointsSummary.fromJson always
    // produces a stable balance regardless of how many times we parse
    // the same API response.

    final apiResponse = {
      'balance': 90,
      'history': [
        {
          'id': 3,
          'type': 'attendance',
          'points': 50,
          'meta': {
            'show_id': 5,
            'ticket_code': 'AT-2026-000012',
            'checked_in_at': '2026-02-06T20:15:00.000000Z',
            'points_awarded': 50,
          },
          'created_at': '2026-02-06T20:15:00.000000Z',
        },
        {
          'id': 2,
          'type': 'attendance',
          'points': 20,
          'meta': {
            'show_id': 3,
            'ticket_code': 'AT-2026-000008',
            'checked_in_at': '2026-02-01T19:30:00.000000Z',
            'points_awarded': 20,
          },
          'created_at': '2026-02-01T19:30:00.000000Z',
        },
        {
          'id': 1,
          'type': 'attendance',
          'points': 20,
          'meta': {
            'show_id': 1,
            'ticket_code': 'AT-2026-000003',
            'checked_in_at': '2026-01-25T20:00:00.000000Z',
            'points_awarded': 20,
          },
          'created_at': '2026-01-25T20:00:00.000000Z',
        },
      ],
    };

    test('balance is the sum reflected by the backend (not re-computed)', () {
      final summary = PointsSummary.fromJson(apiResponse);
      expect(summary.balance, 90);
    });

    test('history contains exactly 3 entries (no duplicates on re-parse)', () {
      final s1 = PointsSummary.fromJson(apiResponse);
      final s2 = PointsSummary.fromJson(apiResponse);
      expect(s1.history.length, 3);
      expect(s2.history.length, 3);
    });

    test('each entry has a unique ledger id', () {
      final summary = PointsSummary.fromJson(apiResponse);
      final ids = summary.history.map((e) => e.id).toSet();
      expect(ids.length, summary.history.length,
          reason: 'Ledger IDs must be unique — no duplicate entries');
    });

    test('points entries are positive (attendance only in MVP)', () {
      final summary = PointsSummary.fromJson(apiResponse);
      for (final entry in summary.history) {
        expect(entry.isPositive, isTrue);
        expect(entry.points, greaterThan(0));
      }
    });

    test('meta contains show_id and ticket_code for traceability', () {
      final summary = PointsSummary.fromJson(apiResponse);
      for (final entry in summary.history) {
        expect(entry.meta, isNotNull);
        expect(entry.meta!.containsKey('show_id'), isTrue);
        expect(entry.meta!.containsKey('ticket_code'), isTrue);
      }
    });

    test('formattedPoints shows + prefix for positive entries', () {
      final summary = PointsSummary.fromJson(apiResponse);
      for (final entry in summary.history) {
        expect(entry.formattedPoints, startsWith('+'));
      }
    });

    test('PointsSummary.empty gives 0 balance and empty history', () {
      expect(PointsSummary.empty.balance, 0);
      expect(PointsSummary.empty.history, isEmpty);
    });
  });
}
