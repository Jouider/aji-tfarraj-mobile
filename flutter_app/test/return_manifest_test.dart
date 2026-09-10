import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/staff/data/return_manifest_export.dart';
import 'package:aji_tfarraj/features/staff/domain/return_manifest.dart';

/// Vehicles get dispatched off these numbers. The two ways to be wrong both
/// strand someone: counting people who never came sends a half-empty bus, and
/// dropping a passenger whose stop was edited mid-evening leaves them at the
/// studio.
void main() {
  Map<String, dynamic> point({
    int id = 3,
    String name = 'Ain Sebaa',
    String? nameAr,
    String? landmark = 'devant la gare',
    bool served = true,
    int people = 4,
    int tickets = 2,
    List<Map<String, dynamic>>? passengers,
  }) =>
      {
        'id': id,
        'name': name,
        'name_ar': nameAr,
        'landmark': landmark,
        'served': served,
        'people': people,
        'tickets': tickets,
        'passengers': passengers ??
            [
              {'name': 'Ahmed Bennani', 'seats': 3},
              {'name': 'Salma Idrissi', 'seats': 1},
            ],
      };

  Map<String, dynamic> payload({
    bool hasShuttle = true,
    List<Map<String, dynamic>>? points,
    Map<String, dynamic>? totals,
  }) =>
      {
        'episode': {
          'id': 10,
          'title': 'Épisode 12',
          'starts_at': '2026-09-09T19:00:00',
          'studio': 'Studio 2M Ain Sebaa',
          'city': 'Casablanca',
        },
        'show': {'id': 1, 'title': 'Saat Saraha'},
        'generated_at': '2026-09-09T23:10:00',
        'has_shuttle': hasShuttle,
        'totals': totals ??
            {
              'checked_in_people': 12,
              'checked_in_tickets': 8,
              'riders': 4,
              'own_means': 8,
            },
        'points': points ?? [point()],
      };

  group('reading the sheet', () {
    /// A booking is capped at one seat by the API, so `people` and `tickets`
    /// normally match. The two are still read apart: older multi-seat rows
    /// exist, and under-reporting one would leave someone at the kerb.
    test('parses the headcount the dispatcher sizes vehicles from', () {
      final m = ReturnManifest.fromJson(payload());

      expect(m.checkedInPeople, 12);
      expect(m.riders, 4);
      expect(m.ownMeans, 8);
      expect(m.hasShuttle, isTrue);
      expect(m.points.single.people, 4);
      expect(m.points.single.tickets, 2);
      expect(m.showTitle, 'Saat Saraha');
      expect(m.episode.studio, 'Studio 2M Ain Sebaa');
    });

    test('names the passengers, and any legacy group size', () {
      final m = ReturnManifest.fromJson(payload());

      expect(m.points.single.passengers, hasLength(2));
      expect(m.points.single.passengers.first.name, 'Ahmed Bennani');
      expect(m.points.single.passengers.first.seats, 3);
    });

    test('missing optional fields do not break the sheet', () {
      final m = ReturnManifest.fromJson({'episode': {'id': 7}});

      expect(m.episode.id, 7);
      expect(m.points, isEmpty);
      expect(m.checkedInPeople, 0);
      expect(m.hasShuttle, isFalse);
    });
  });

  group('stops', () {
    /// A stop nobody chose still belongs on the sheet — that is how the
    /// dispatcher knows not to send a vehicle, rather than assuming an
    /// oversight.
    test('an empty stop is kept but marked empty', () {
      final m = ReturnManifest.fromJson(payload(points: [
        point(id: 1, name: 'Maarif', people: 0, tickets: 0, passengers: []),
        point(id: 2, name: 'Zenata', people: 5),
      ]));

      expect(m.points, hasLength(2));
      expect(m.points.first.isEmpty, isTrue);
      // Only the stop with people is a vehicle actually going somewhere.
      expect(m.servedTonight.map((p) => p.name), ['Zenata']);
    });

    /// Someone whose stop was retired after they chose it is still standing
    /// outside. The sheet must shout about it, not quietly drop them.
    test('a passenger on a retired stop raises a flag', () {
      final m = ReturnManifest.fromJson(payload(points: [
        point(id: 1, name: 'Retiré', served: false, people: 2),
      ]));

      expect(m.hasOrphanedPassengers, isTrue);
    });

    test('a retired stop nobody chose raises nothing', () {
      final m = ReturnManifest.fromJson(payload(points: [
        point(id: 1, name: 'Retiré', served: false, people: 0, passengers: []),
      ]));

      expect(m.hasOrphanedPassengers, isFalse);
    });

    test('the Arabic label falls back to French when absent', () {
      final withAr = ManifestPoint.fromJson(
          point(nameAr: 'عين السبع'));
      final withoutAr = ManifestPoint.fromJson(point(nameAr: null));

      expect(withAr.localizedName(true), 'عين السبع');
      expect(withAr.localizedName(false), 'Ain Sebaa');
      expect(withoutAr.localizedName(true), 'Ain Sebaa');
    });
  });

  group('naming the recording', () {
    test('uses the episode title when there is one', () {
      expect(
        ManifestEpisode.fromJson({'id': 1, 'title': 'Épisode 12'}).label,
        'Épisode 12',
      );
    });

    /// Episodes are routinely untitled, and then the show name is the only
    /// thing that identifies the evening.
    test('falls back to the show, then to the id', () {
      expect(
        ManifestEpisode.fromJson({'id': 1, 'show_title': 'Saat Saraha'}).label,
        'Saat Saraha',
      );
      expect(ManifestEpisode.fromJson({'id': 42}).label, 'Tournage #42');
    });
  });

  group('the message sent to transport', () {
    test('carries every stop with its headcount, and the totals', () {
      final text = ReturnManifestExport.buildText(
        ReturnManifest.fromJson(payload(points: [
          point(id: 1, name: 'Maarif', people: 6),
          point(id: 2, name: 'Zenata', people: 0, passengers: []),
        ])),
      );

      expect(text, contains('Maarif : 6 pers.'));
      expect(text, contains('Total navette : 4 pers.'));
      expect(text, contains('Repartent seules : 8 pers.'));
      // An empty stop is noise in a WhatsApp message — the sheet already says
      // it, and the driver is not going there.
      expect(text, isNot(contains('Zenata')));
    });

    test('flags a retired stop, so nobody is quietly left behind', () {
      final text = ReturnManifestExport.buildText(
        ReturnManifest.fromJson(payload(points: [
          point(id: 1, name: 'Retiré', served: false, people: 2),
        ])),
      );

      expect(text, contains('hors liste'));
    });

    test('says plainly when nobody is waiting', () {
      final text = ReturnManifestExport.buildText(
        ReturnManifest.fromJson(payload(points: [])),
      );

      expect(text, contains('Personne n\'attend la navette.'));
    });

    /// This message gets forwarded on, so it must not carry phone numbers.
    test('never carries a phone number', () {
      final text = ReturnManifestExport.buildText(
        ReturnManifest.fromJson(payload()),
      );

      expect(RegExp(r'\+?\d{9,}').hasMatch(text), isFalse);
    });
  });
}
