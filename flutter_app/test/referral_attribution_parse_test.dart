import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/referral/data/referral_attribution_service.dart';

void main() {
  group('ReferralAttributionService.parseToken', () {
    test('parses a bare referral_token payload (Android install referrer)', () {
      expect(
        ReferralAttributionService.parseToken('referral_token=ABC123def456'),
        'ABC123def456',
      );
    });

    test('parses a token embedded in a query-like blob', () {
      expect(
        ReferralAttributionService.parseToken(
            'utm_source=cp&referral_token=TOKEN64&utm_medium=link'),
        'TOKEN64',
      );
    });

    test('decodes a URL-encoded referrer (referral_token%3D...)', () {
      expect(
        ReferralAttributionService.parseToken('referral_token%3DENC0DED'),
        'ENC0DED',
      );
    });

    test('handles a trailing token at the end of the blob', () {
      expect(
        ReferralAttributionService.parseToken('a=1&referral_token=zzz'),
        'zzz',
      );
    });

    test('returns null when no token is present (organic clipboard text)', () {
      expect(ReferralAttributionService.parseToken('hello world'), isNull);
      expect(ReferralAttributionService.parseToken(''), isNull);
      expect(ReferralAttributionService.parseToken('utm_source=cp'), isNull);
    });

    test('returns null for an empty token value', () {
      expect(ReferralAttributionService.parseToken('referral_token='), isNull);
      expect(
          ReferralAttributionService.parseToken('referral_token=&x=1'), isNull);
    });
  });
}
