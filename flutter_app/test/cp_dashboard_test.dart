import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/charge_public/domain/cp_dashboard.dart';

/// A charge public is paid per recording, and asked to see which night paid
/// what. The per-episode rows come from the server with the same rule as the
/// show total, so the app only has to read them faithfully.
void main() {
  Map<String, dynamic> show({List<dynamic>? episodes}) => {
        'show_id': 4,
        'show_title': 'Saat Saraha',
        'show_date': '12/09/2026 19:00',
        'invited': 217,
        'attended': 98,
        'not_attended': 119,
        'earnings': 1380,
        if (episodes != null) 'episodes': episodes,
      };

  Map<String, dynamic> episode({
    int? id = 11,
    String? startsAt = '2026-09-12T18:00:00.000000Z',
    int earnings = 900,
  }) =>
      {
        'episode_id': id,
        'title': null,
        'starts_at': startsAt,
        'invited': 120,
        'attended': 60,
        'not_attended': 60,
        'earnings': earnings,
      };

  group('a show row', () {
    test('carries its episodes, in the order the server sent them', () {
      final row = CpShowRow.fromJson(show(episodes: [
        episode(id: 12, startsAt: '2026-09-19T18:00:00.000000Z', earnings: 480),
        episode(id: 11, earnings: 900),
      ]));

      expect(row.showId, 4);
      expect(row.hasEpisodes, isTrue);
      expect(row.episodes.map((e) => e.episodeId), [12, 11]);
      expect(row.episodes.first.earnings, 480);
    });

    /// An older server sends no breakdown. The row must then stay a plain line
    /// — opening an empty sheet would be worse than not opening anything.
    test('without a breakdown it has nothing to open', () {
      final row = CpShowRow.fromJson(show());

      expect(row.episodes, isEmpty);
      expect(row.hasEpisodes, isFalse);
      expect(row.earnings, 1380, reason: 'the totals still read as before');
    });

    test('a malformed entry is skipped rather than breaking the dashboard', () {
      final row = CpShowRow.fromJson(show(episodes: [episode(), 'oops', 42]));

      expect(row.episodes, hasLength(1));
    });
  });

  group('an episode row', () {
    test('parses its date and figures', () {
      final e = CpEpisodeRow.fromJson(episode());

      expect(e.episodeId, 11);
      expect(e.startsAt, isNotNull);
      expect(e.invited, 120);
      expect(e.attended, 60);
      expect(e.earnings, 900);
    });

    /// Guests recorded before episodes were tracked land in one undated row,
    /// so the episodes still add up to the show.
    test('the undated bucket has no id and no date', () {
      final e = CpEpisodeRow.fromJson(episode(id: null, startsAt: null));

      expect(e.episodeId, isNull);
      expect(e.startsAt, isNull);
    });

    test('an unparseable date reads as undated instead of crashing', () {
      expect(CpEpisodeRow.fromJson(episode(startsAt: 'not a date')).startsAt,
          isNull);
    });
  });
}
