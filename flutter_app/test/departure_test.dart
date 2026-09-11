import 'package:flutter_test/flutter_test.dart';

import 'package:aji_tfarraj/features/staff/domain/attendee.dart';
import 'package:aji_tfarraj/features/staff/domain/ticket_preview.dart';

/// "Présents" and the departures recorded on it, as the app reads them.
void main() {
  Map<String, dynamic> row({
    String kind = 'reservation',
    int id = 1,
    String name = 'Amine Benali',
    String? ticket = 'AT-2026-000042',
    Map<String, dynamic>? departure,
    int pastExclusions = 0,
  }) =>
      {
        'kind': kind,
        'id': id,
        'name': name,
        'photo_url': null,
        'ticket_code': ticket,
        'checked_in_at': '2026-09-12T18:05:00+00:00',
        'charge_public': 'Karim CP',
        'has_account': kind == 'reservation',
        'departure': departure,
        'past_exclusions': pastExclusions,
        'last_exclusion_at': pastExclusions > 0 ? '2026-08-01T21:00:00+00:00' : null,
      };

  group('an attendee', () {
    test('parses a member who stayed', () {
      final a = Attendee.fromJson(row());

      expect(a.kind, AttendeeKind.reservation);
      expect(a.name, 'Amine Benali');
      expect(a.ticketCode, 'AT-2026-000042');
      expect(a.chargePublic, 'Karim CP');
      expect(a.hasAccount, isTrue);
      expect(a.hasLeft, isFalse);
      expect(a.wasExcludedBefore, isFalse);
    });

    test('parses a walk-in, who has no account', () {
      final a = Attendee.fromJson(row(kind: 'walk_in', ticket: null));

      expect(a.kind, AttendeeKind.walkIn);
      expect(a.kind.key, 'walk_in');
      expect(a.hasAccount, isFalse);
    });

    test('parses a departure and who recorded it', () {
      final a = Attendee.fromJson(row(departure: {
        'at': '2026-09-12T19:32:00+00:00',
        'reason': 'excluded',
        'label': 'Exclu : comportement',
        'note': 'Téléphone pendant le tournage',
        'recorded_by': 'Sara Staff',
      }));

      expect(a.hasLeft, isTrue);
      expect(a.departure!.reason, DepartureReason.excluded);
      expect(a.departure!.isExclusion, isTrue);
      expect(a.departure!.note, 'Téléphone pendant le tournage');
      expect(a.departure!.recordedBy, 'Sara Staff');
    });

    test('carries exclusions from earlier recordings', () {
      final a = Attendee.fromJson(row(pastExclusions: 2));

      expect(a.wasExcludedBefore, isTrue);
      expect(a.pastExclusions, 2);
      expect(a.lastExclusionAt, isNotNull);
    });

    /// An unreadable departure must never hide that the person is still here —
    /// but a reason this build does not know still counts as having left.
    test('a departure without a time reads as none; an unknown reason still left', () {
      expect(Attendee.fromJson(row(departure: {'reason': 'left'})).hasLeft,
          isFalse);

      final a = Attendee.fromJson(row(departure: {
        'at': '2026-09-12T19:32:00+00:00',
        'reason': 'teleported',
      }));
      expect(a.hasLeft, isTrue);
      expect(a.departure!.reason, DepartureReason.unknown);
    });
  });

  group('the reasons', () {
    test('the four offered, in order, and only "Autre" needs a note', () {
      expect(DepartureReason.choices.map((r) => r.key),
          ['left', 'unwell', 'excluded', 'other']);
      expect(DepartureReason.choices.where((r) => r.needsNote),
          [DepartureReason.other]);
    });

    test('an unknown key is never mistaken for a real reason', () {
      expect(DepartureReason.fromKey(''), DepartureReason.unknown);
      expect(DepartureReason.fromKey(null), DepartureReason.unknown);
      expect(DepartureReason.fromKey('unwell'), DepartureReason.unwell);
    });
  });

  group('the list', () {
    final list = AttendeeList.fromJson({
      'episode': {
        'id': 9,
        'title': 'Épisode 12',
        'show_title': 'Rachid Show',
        'starts_at': '2026-09-12T18:00:00+00:00',
      },
      'attendees': [
        row(id: 1, name: 'Amine Benali', ticket: 'AT-2026-000042'),
        row(id: 2, name: 'Hélène Dupré', ticket: 'AT-2026-000077'),
        row(
          id: 3,
          name: 'Youssef El Idrissi',
          ticket: 'AT-2026-000101',
          departure: {'at': '2026-09-12T19:00:00+00:00', 'reason': 'left'},
        ),
        row(kind: 'walk_in', id: 1, name: 'Fatima', ticket: null),
      ],
    });

    test('parses the recording and counts who is still here', () {
      expect(list.showTitle, 'Rachid Show');
      expect(list.episodeTitle, 'Épisode 12');
      expect(list.attendees, hasLength(4));
      expect(list.presentCount, 3);
      expect(list.leftCount, 1);
    });

    test('finds a name in any case, without the accents', () {
      expect(list.search('helene').single.name, 'Hélène Dupré');
      expect(list.search('DUPRÉ').single.name, 'Hélène Dupré');
    });

    test('finds a name from parts, in any order', () {
      expect(list.search('benali amine').single.id, 1);
      expect(list.search('el idri').single.id, 3);
    });

    test('finds a ticket code', () {
      expect(list.search('000077').single.name, 'Hélène Dupré');
      expect(list.search('at-2026-000101').single.id, 3);
    });

    test('an empty search is everyone', () {
      expect(list.search('   '), hasLength(4));
    });

    /// A member and a walk-in can share an id: they are different people.
    test('replacing a row changes only that person', () {
      final left = Attendee.fromJson(row(
        id: 1,
        departure: {'at': '2026-09-12T19:40:00+00:00', 'reason': 'unwell'},
      ));

      final updated = list.replacing(left);

      expect(updated.attendees.first.hasLeft, isTrue);
      expect(updated.leftCount, 2);
      final walkIn =
          updated.attendees.firstWhere((a) => a.kind == AttendeeKind.walkIn);
      expect(walkIn.hasLeft, isFalse);
    });
  });

  group('the door preview', () {
    Map<String, dynamic> lookup({Map<String, dynamic>? exclusions, Map<String, dynamic>? departure}) => {
          'status': 'can_check_in',
          'ticket_code': 'AT-2026-000042',
          'attendee': {
            'id': 5,
            'name': 'Amine Benali',
            if (exclusions != null) 'exclusions': exclusions,
          },
          'reservation': {'id': 12, 'seats': 1, 'departure': departure},
          'return_points': [],
        };

    test('warns about an exclusion from an earlier recording', () {
      final p = TicketPreview.fromJson(lookup(exclusions: {
        'count': 1,
        'last_at': '2026-08-01T21:00:00+00:00',
        'last_show': 'Rachid Show',
      }));

      expect(p.wasExcludedBefore, isTrue);
      expect(p.pastExclusions, 1);
      expect(p.lastExclusionShow, 'Rachid Show');
      expect(p.lastExclusionAt, isNotNull);
    });

    test('an older server sends no exclusions: no warning', () {
      final p = TicketPreview.fromJson(lookup());

      expect(p.wasExcludedBefore, isFalse);
      expect(p.departure, isNull);
    });

    test('knows when this ticket\'s holder already left tonight', () {
      final p = TicketPreview.fromJson(lookup(departure: {
        'at': '2026-09-12T19:32:00+00:00',
        'reason': 'excluded',
      }));

      expect(p.departure?.isExclusion, isTrue);
    });

    /// The copies made while the scanner works must not drop the warning.
    test('the warning survives choosing a stop and replacing the photo', () {
      final p = TicketPreview.fromJson(lookup(
        exclusions: {'count': 2, 'last_at': null, 'last_show': null},
        departure: {'at': '2026-09-12T19:32:00+00:00', 'reason': 'left'},
      ));

      for (final copy in [p.withReturnPoint(3), p.withAvatarUrl('https://x/y.jpg')]) {
        expect(copy.pastExclusions, 2);
        expect(copy.departure, isNotNull);
      }
    });
  });
}
