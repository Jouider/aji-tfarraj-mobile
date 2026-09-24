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

  group('retour en navette', () {
    Map<String, dynamic> withShuttle({
      List<Map<String, dynamic>>? points,
      Map<String, dynamic>? chosen,
    }) {
      final p = payload();
      p['return_points'] = points ??
          [
            {'id': 3, 'name': 'Ain Sebaa', 'name_ar': null, 'landmark': 'devant la gare'},
            {'id': 4, 'name': 'Maarif', 'name_ar': null, 'landmark': null},
          ];
      (p['reservation'] as Map<String, dynamic>)['return_point'] = chosen;
      return p;
    }

    test('parses the stops served tonight', () {
      final p = TicketPreview.fromJson(withShuttle());

      expect(p.returnPoints, hasLength(2));
      expect(p.returnPoints.first.name, 'Ain Sebaa');
      expect(p.returnPoints.first.landmark, 'devant la gare');
      expect(p.asksReturnPoint, isTrue);
    });

    /// No served stop means no vehicle, so the door must not ask at all.
    test('no stops means the question is not asked', () {
      final p = TicketPreview.fromJson(withShuttle(points: []));

      expect(p.asksReturnPoint, isFalse);
      expect(p.chosenReturnPointId, isNull);
    });

    test('a payload without the field at all does not ask', () {
      expect(TicketPreview.fromJson(payload()).asksReturnPoint, isFalse);
    });

    test('an earlier answer comes back, so the scanner does not ask twice', () {
      final p = TicketPreview.fromJson(
          withShuttle(chosen: {'id': 4, 'name': 'Maarif'}));

      expect(p.chosenReturnPointId, 4);
    });

    test('recording a choice keeps everything else intact', () {
      final p = TicketPreview.fromJson(withShuttle());
      final updated = p.withReturnPoint(3);

      expect(updated.chosenReturnPointId, 3);
      expect(updated.returnPoints, hasLength(2));
      expect(updated.ticketCode, p.ticketCode);
      expect(updated.attendeeName, p.attendeeName);
      expect(updated.canAdmit, isTrue);
    });

    /// "I drive myself" is a real answer and must be as easy to record.
    test('the choice can be cleared', () {
      final p = TicketPreview.fromJson(
          withShuttle(chosen: {'id': 4, 'name': 'Maarif'}));

      expect(p.withReturnPoint(null).chosenReturnPointId, isNull);
    });

    test('the Arabic label falls back to French when absent', () {
      final p = TicketPreview.fromJson(withShuttle(points: [
        {'id': 3, 'name': 'Ain Sebaa', 'name_ar': 'عين السبع'},
        {'id': 4, 'name': 'Maarif'},
      ]));

      expect(p.returnPoints[0].localizedName(true), 'عين السبع');
      expect(p.returnPoints[1].localizedName(true), 'Maarif');
      expect(p.returnPoints[0].localizedName(false), 'Ain Sebaa');
    });
  });

  group('le retour, avant de valider', () {
    Map<String, dynamic> withShuttle({
      bool answered = false,
      int? chosen,
      bool shuttle = true,
    }) {
      final json = payload(reservation: {
        'id': 5933,
        'seats': 1,
        'return_point_answered': answered,
        if (chosen != null) 'return_point': {'id': chosen, 'name': 'Casa-Port'},
      });
      json['return_points'] = shuttle
          ? [
              {'id': 1, 'name': 'Casa-Port'},
              {'id': 2, 'name': 'Ain Diab'},
            ]
          : <dynamic>[];
      return json;
    }

    /// Sans réponse, valider reviendrait à décider que la personne repart
    /// seule sans le lui avoir demandé.
    test('tant que personne n\'a répondu, on ne peut pas valider', () {
      final p = TicketPreview.fromJson(withShuttle());

      expect(p.canAdmit, isTrue, reason: 'le billet lui-même est bon');
      expect(p.awaitsReturnPoint, isTrue);
    });

    test('un arrêt choisi en réservant règle la question', () {
      final p = TicketPreview.fromJson(withShuttle(answered: true, chosen: 1));

      expect(p.chosenReturnPointId, 1);
      expect(p.awaitsReturnPoint, isFalse);
    });

    /// « Repart par ses propres moyens » est une réponse : aucun arrêt, mais
    /// la question est réglée.
    test('« repart seul » est une réponse, même sans arrêt', () {
      final p = TicketPreview.fromJson(withShuttle(answered: true));

      expect(p.chosenReturnPointId, isNull);
      expect(p.awaitsReturnPoint, isFalse);
    });

    test('sans navette, la question ne se pose pas', () {
      final p = TicketPreview.fromJson(withShuttle(shuttle: false));

      expect(p.asksReturnPoint, isFalse);
      expect(p.awaitsReturnPoint, isFalse, reason: 'rien ne doit bloquer la porte');
    });

    test('choisir à la porte règle la question sur-le-champ', () {
      final p = TicketPreview.fromJson(withShuttle());

      expect(p.withReturnPoint(2).awaitsReturnPoint, isFalse);
      expect(p.withReturnPoint(null).awaitsReturnPoint, isFalse,
          reason: 'y compris quand la porte répond « repart seul »');
    });

    /// Un serveur d'avant la fonction n'envoie pas le drapeau : la porte ne
    /// doit pas se retrouver bloquée par une version plus ancienne.
    test('un vieux serveur ne bloque pas la porte', () {
      final json = payload(reservation: {'id': 5933, 'seats': 1});
      json['return_points'] = <dynamic>[];

      expect(TicketPreview.fromJson(json).awaitsReturnPoint, isFalse);
    });
  });
}
