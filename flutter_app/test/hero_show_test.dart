import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/home/hero_show.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';

void main() {
  final now = DateTime(2026, 10, 30, 12);

  Map<String, dynamic> episode(int id, DateTime? startsAt) => {
        'id': id,
        'show_id': id,
        'starts_at': startsAt?.toIso8601String(),
        'is_active': true,
        'capacity': 100,
        'reserved_seats': 0,
      };

  Show show(int id, String title,
          {DateTime? startsAt,
          bool featured = false,
          bool active = true,
          bool upcoming = true,
          int reserved = 0}) =>
      Show.fromJson({
        'id': id,
        'title': title,
        'is_active': active,
        'is_featured': featured,
        'starts_at': startsAt?.toIso8601String(),
        'next_episode': upcoming ? episode(id, startsAt) : null,
        'capacity': 100,
        'reserved_seats': reserved,
      });

  test('the show « à la une » is the hero even when another one is sooner', () {
    final shows = [
      show(1, 'Planet Foot', startsAt: now.add(const Duration(days: 1))),
      show(2, 'Starlight',
          startsAt: now.add(const Duration(days: 7)), featured: true),
    ];

    expect(pickHeroShow(shows, now).title, 'Starlight');
  });

  test('a featured show with no date yet still wins', () {
    final shows = [
      show(1, 'Planet Foot', startsAt: now.add(const Duration(days: 1))),
      show(2, 'Starlight', featured: true),
    ];

    expect(pickHeroShow(shows, now).title, 'Starlight');
  });

  test('a featured show nobody can book any more falls back to the soonest',
      () {
    final shows = [
      show(1, 'Planet Foot', startsAt: now.add(const Duration(days: 1))),
      show(2, 'Starlight', featured: true, upcoming: false),
    ];

    expect(pickHeroShow(shows, now).title, 'Planet Foot');
  });

  test('without a featured show the soonest upcoming one is the hero', () {
    final shows = [
      show(1, 'Dans une semaine', startsAt: now.add(const Duration(days: 7))),
      show(2, 'Demain', startsAt: now.add(const Duration(days: 1))),
    ];

    expect(pickHeroShow(shows, now).title, 'Demain');
  });

  test('older backends without is_featured keep the date-based hero', () {
    final s = Show.fromJson({'id': 1, 'title': 'X', 'capacity': 0});

    expect(s.isFeatured, isFalse);
  });
}
