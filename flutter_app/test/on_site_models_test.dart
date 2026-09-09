import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/on_site/domain/on_site_models.dart';

/// The door screen reads these straight off the API response, so a silent
/// parsing slip would show staff the wrong password or hide the episode list.
void main() {
  group('OnSiteRegistrationResult', () {
    test('reads the account and the credentials to read out', () {
      final result = OnSiteRegistrationResult.fromJson({
        'user': {'id': 42, 'name': 'Ahmed Bennani', 'avatar_url': 'https://x/a.jpg'},
        'credentials': {
          'email': 'ahmed.bennani@porte.ajitfarraj.ma',
          'password': 'kfr7mq2p',
          'email_generated': true,
        },
        'reward_amount': 35,
        'episode_id': 7,
      });

      expect(result.userId, 42);
      expect(result.name, 'Ahmed Bennani');
      expect(result.email, 'ahmed.bennani@porte.ajitfarraj.ma');
      expect(result.password, 'kfr7mq2p');
      expect(result.emailGenerated, isTrue);
      expect(result.rewardAmount, 35);
    });

    test('a supplied email is not flagged as generated', () {
      final result = OnSiteRegistrationResult.fromJson({
        'user': {'id': 1, 'name': 'Sara'},
        'credentials': {
          'email': 'sara@example.com',
          'password': 'abcd2345',
          'email_generated': false,
        },
      });

      expect(result.emailGenerated, isFalse);
      expect(result.rewardAmount, isNull);
    });

    test('a response with no charge public still parses (no reward)', () {
      final result = OnSiteRegistrationResult.fromJson({
        'user': {'id': 3, 'name': 'Youssef'},
        'credentials': {'email': 'y@x.ma', 'password': 'pw234567'},
        'reward_amount': null,
      });

      expect(result.rewardAmount, isNull);
      expect(result.emailGenerated, isFalse);
    });
  });

  group('OnSiteShow / OnSiteEpisode', () {
    test('parses shows with their open episodes', () {
      final show = OnSiteShow.fromJson({
        'id': 5,
        'title': 'Saat Saraha',
        'city': 'Casablanca',
        'episodes': [
          {
            'id': 10,
            'title': 'episode 10',
            'starts_at': '2026-09-05T19:00:00',
            'studio': 'Studio 2M Ain Sebaa',
            'capacity': 300,
            'reserved_seats': 255,
          },
        ],
      });

      expect(show.title, 'Saat Saraha');
      expect(show.episodes, hasLength(1));

      final ep = show.episodes.first;
      expect(ep.id, 10);
      expect(ep.startsAt, DateTime(2026, 9, 5, 19));
      expect(ep.availableSeats, 45);
    });

    test('seat count is null rather than wrong when the API omits it', () {
      final ep = OnSiteEpisode.fromJson({'id': 1});

      expect(ep.availableSeats, isNull);
      expect(ep.startsAt, isNull);
    });

    test('a show with no episodes parses to an empty list', () {
      final show = OnSiteShow.fromJson({'id': 2, 'title': 'Jam Show'});

      expect(show.episodes, isEmpty);
    });
  });

  group('ChargePublicOption', () {
    test('parses a charge public with its referral code', () {
      final cp = ChargePublicOption.fromJson({
        'id': 9,
        'name': 'Oussama Chahri',
        'referral_code': 'CP1234',
      });

      expect(cp.id, 9);
      expect(cp.name, 'Oussama Chahri');
      expect(cp.referralCode, 'CP1234');
    });

    test('a missing referral code stays null', () {
      final cp = ChargePublicOption.fromJson({'id': 4, 'name': 'Sabrine'});

      expect(cp.referralCode, isNull);
    });
  });
}
