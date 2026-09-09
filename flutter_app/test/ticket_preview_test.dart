import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/staff/domain/ticket_preview.dart';

/// The scanner decides who gets in from this object, so a parsing slip would
/// either admit someone who should be refused, or turn away a valid ticket.
void main() {
  Map<String, dynamic> payload({
    String status = 'can_check_in',
    String? reason,
    Map<String, dynamic>? attendee,
    Map<String, dynamic>? reservation,
  }) =>
      {
        'status': status,
        'reason': reason,
        'ticket_code': 'AT-2026-000002',
        'checked_in_at': null,
        'attendee': attendee ??
            {
              'id': 71,
              'name': 'Ahmed Bennani',
              'avatar_url': 'https://x/a.jpg',
              'avatar_locked': false,
              'phone': '+212 612345678',
              'is_minor': false,
            },
        'reservation': reservation ?? {'id': 5933, 'seats': 2},
        'episode': {
          'id': 10,
          'title': 'episode 10',
          'starts_at': '2026-09-05T19:00:00',
          'studio': 'Studio 2M Ain Sebaa',
        },
        'show': {'id': 1, 'title': 'Saat Saraha'},
      };

  group('reading the ticket', () {
    test('parses everything the scanner needs to decide', () {
      final p = TicketPreview.fromJson(payload());

      expect(p.status, TicketPreviewStatus.canCheckIn);
      expect(p.attendeeName, 'Ahmed Bennani');
      expect(p.seats, 2);
      expect(p.episodeTitle, 'episode 10');
      expect(p.showTitle, 'Saat Saraha');
      expect(p.ticketCode, 'AT-2026-000002');
      expect(p.canAdmit, isTrue);
    });

    test('an unknown status blocks rather than admits', () {
      // Admitting on a rule this build cannot read would be worse than asking
      // staff to look.
      final p = TicketPreview.fromJson(payload(status: 'some_future_rule'));

      expect(p.status, TicketPreviewStatus.unknown);
      expect(p.canAdmit, isFalse);
    });
  });

  group('refusals', () {
    test('a wrong date carries the reason, so staff know what to say', () {
      final past = TicketPreview.fromJson(
          payload(status: 'wrong_date', reason: 'past'));
      final future = TicketPreview.fromJson(
          payload(status: 'wrong_date', reason: 'future'));

      expect(past.reason, WrongDateReason.past);
      expect(future.reason, WrongDateReason.future);
      expect(past.canAdmit, isFalse);
      expect(future.canAdmit, isFalse);
    });

    test('an already used ticket cannot be admitted again', () {
      final p = TicketPreview.fromJson(payload(status: 'already_checked_in'));

      expect(p.canAdmit, isFalse);
    });

    test('an unapproved reservation cannot be admitted', () {
      expect(
        TicketPreview.fromJson(payload(status: 'not_approved')).canAdmit,
        isFalse,
      );
    });
  });

  group('replacing the photo', () {
    test('is offered for a normal attendee', () {
      expect(TicketPreview.fromJson(payload()).canReplacePhoto, isTrue);
    });

    test('is refused when an admin locked the avatar', () {
      final p = TicketPreview.fromJson(payload(attendee: {
        'id': 71,
        'name': 'Ahmed',
        'avatar_locked': true,
      }));

      expect(p.canReplacePhoto, isFalse);
    });

    test('is refused when there is no account behind the ticket', () {
      final p = TicketPreview.fromJson(payload(attendee: {'name': 'Inconnu'}));

      expect(p.attendeeId, isNull);
      expect(p.canReplacePhoto, isFalse);
    });

    test('a new photo updates the preview without losing anything else', () {
      final p = TicketPreview.fromJson(payload());
      final updated = p.withAvatarUrl('https://x/new.jpg');

      expect(updated.attendeeAvatarUrl, 'https://x/new.jpg');
      // Everything the scanner is about to act on must survive the swap.
      expect(updated.status, p.status);
      expect(updated.ticketCode, p.ticketCode);
      expect(updated.seats, p.seats);
      expect(updated.attendeeId, p.attendeeId);
      expect(updated.canAdmit, isTrue);
    });
  });

  group('flags shown at the door', () {
    test('a minor is flagged', () {
      final p = TicketPreview.fromJson(payload(attendee: {
        'id': 1,
        'name': 'Jeune',
        'is_minor': true,
      }));

      expect(p.isMinor, isTrue);
    });

    test('missing optional fields do not break the preview', () {
      final p = TicketPreview.fromJson({'status': 'can_check_in'});

      expect(p.attendeeName, '');
      expect(p.seats, 1);
      expect(p.episodeStartsAt, isNull);
      expect(p.canAdmit, isTrue);
    });
  });
}
