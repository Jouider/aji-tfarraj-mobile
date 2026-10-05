import 'package:aji_tfarraj/features/return_points/domain/return_point_option.dart';
import 'package:aji_tfarraj/features/staff/domain/attendee.dart';
import 'package:flutter_test/flutter_test.dart';

/// Changer le point de retour d'un client déjà entré, depuis la liste des
/// présents — sans rescanner son billet.
void main() {
  const maarif = ReturnPointOption(id: 2, name: 'Maârif');

  Map<String, dynamic> ligne({
    Map<String, dynamic>? point,
    bool answered = true,
    String? changedAt,
    String kind = 'reservation',
    Map<String, dynamic>? departure,
  }) =>
      {
        'kind': kind,
        'id': 42,
        'name': 'Sara Idrissi',
        'checked_in_at': '2026-10-05T20:00:00Z',
        'has_account': true,
        'return_point': point,
        'return_point_answered': answered,
        'return_point_changed_at': changedAt,
        'departure': departure,
      };

  test('la liste lit le point de chacun et les arrêts de ce soir', () {
    final list = AttendeeList.fromJson({
      'episode': {
        'show_title': 'Jam Show',
        'return_points': [
          {'id': 1, 'name': 'Hay Hassani'},
          {'id': 2, 'name': 'Maârif'},
        ],
      },
      'attendees': [
        ligne(point: {'id': 1, 'name': 'Hay Hassani'}),
      ],
    });

    expect(list.returnPoints.map((p) => p.name), ['Hay Hassani', 'Maârif']);
    expect(list.attendees.single.returnPointName, 'Hay Hassani');
    expect(list.attendees.single.returnPointAnswered, isTrue);
  });

  test('les arrêts survivent au remplacement d\'une ligne', () {
    final list = AttendeeList.fromJson({
      'episode': {
        'show_title': 'Jam Show',
        'return_points': [
          {'id': 2, 'name': 'Maârif'}
        ],
      },
      'attendees': [ligne()],
    });

    final apres = list.replacing(list.attendees.single.withReturnPoint(maarif));

    expect(apres.returnPoints, hasLength(1));
    expect(apres.attendees.single.returnPointName, 'Maârif');
  });

  test('un vrai déplacement est daté, reconfirmer le même arrêt ne l\'est pas', () {
    final a = Attendee.fromJson(ligne(point: {'id': 2, 'name': 'Maârif'}));

    expect(a.withReturnPoint(maarif).returnPointChangedAt, isNull);
    expect(a.withReturnPoint(null).returnPointChangedAt, isNotNull);
  });

  test('« par ses propres moyens » est une réponse, pas une absence', () {
    final a = Attendee.fromJson(ligne(answered: false));
    final apres = a.withReturnPoint(null);

    expect(apres.returnPointId, isNull);
    expect(apres.returnPointAnswered, isTrue);
  });

  test('seuls les détenteurs d\'un billet encore présents peuvent changer', () {
    expect(Attendee.fromJson(ligne()).canChangeReturnPoint, isTrue);
    expect(Attendee.fromJson(ligne(kind: 'walk_in')).canChangeReturnPoint,
        isFalse);
    expect(
      Attendee.fromJson(ligne(departure: {
        'at': '2026-10-05T21:00:00Z',
        'reason': 'left',
      })).canChangeReturnPoint,
      isFalse,
    );
  });
}
