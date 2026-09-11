import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/profile/domain/social_handles.dart';

/// Members type "@nom", "Nom", or paste the link copied from the app. All of it
/// must land as the same account — and these rules must match the server's
/// (tests/Feature/SocialAccountsTest.php) exactly.
void main() {
  const ig = SocialPlatform.instagram;
  const tt = SocialPlatform.tiktok;
  const fb = SocialPlatform.facebook;

  String? n(SocialPlatform p, String? raw) => SocialHandles.normalize(p, raw);
  bool ok(SocialPlatform p, String raw) {
    final h = n(p, raw);
    return h != null && SocialHandles.isValid(p, h);
  }

  group('typing the username', () {
    test('"@", capitals and stray spaces are cleaned away', () {
      expect(n(ig, ' @Nom.Test_1 '), 'nom.test_1');
      expect(n(tt, '@@MonCompte'), 'moncompte');
    });

    test('an empty field means "no account", which clears it', () {
      expect(n(ig, ''), isNull);
      expect(n(ig, '   '), isNull);
      expect(n(ig, null), isNull);
    });
  });

  group('pasting a link', () {
    test('an Instagram profile link, with its tracking junk', () {
      expect(n(ig, 'https://www.instagram.com/nom_test/?igsh=abc123'),
          'nom_test');
      expect(n(ig, 'instagram.com/Nom.Test'), 'nom.test');
    });

    test('an Instagram story link still names the account', () {
      expect(n(ig, 'https://instagram.com/stories/nom_test/3123'), 'nom_test');
    });

    test('a TikTok profile link', () {
      expect(n(tt, 'https://www.tiktok.com/@Nom?lang=fr'), 'nom');
      expect(n(tt, 'tiktok.com/@nom.test/video/7123'), 'nom.test');
    });

    test('a Facebook username link, and a numeric profile link', () {
      expect(n(fb, 'https://www.facebook.com/nom.prenom'), 'nom.prenom');
      expect(n(fb, 'https://m.facebook.com/profile.php?id=100012345678'),
          '100012345678');
    });

    /// A post or a short link cannot be turned into a username without the
    /// network. It is refused, and the member is asked for the username.
    test('a link that is not a profile is refused rather than guessed', () {
      expect(ok(ig, 'https://www.instagram.com/p/Cx12AbC/'), isFalse);
      expect(ok(tt, 'https://vm.tiktok.com/ZMabc123/'), isFalse);
      expect(ok(fb, 'https://www.facebook.com/share/abc123/'), isFalse);
    });
  });

  group('what can be saved', () {
    test('valid usernames pass', () {
      expect(ok(ig, 'nom.test_1'), isTrue);
      expect(ok(tt, 'nom.test'), isTrue);
      expect(ok(fb, 'nom.prenom'), isTrue);
      expect(ok(fb, '100012345678'), isTrue);
    });

    test('characters a network does not allow are refused', () {
      expect(ok(ig, 'nom-test'), isFalse);
      expect(ok(ig, 'a' * 31), isFalse);
      expect(ok(tt, 'n'), isFalse);
      expect(ok(fb, 'abc'), isFalse);
    });
  });

  group('opening the profile', () {
    test('each network gets its own address', () {
      expect(SocialHandles.profileUri(ig, 'nom').toString(),
          'https://www.instagram.com/nom/');
      expect(SocialHandles.profileUri(tt, 'nom').toString(),
          'https://www.tiktok.com/@nom');
      expect(SocialHandles.profileUri(fb, 'nom.prenom').toString(),
          'https://www.facebook.com/nom.prenom');
      expect(SocialHandles.profileUri(fb, '100012345678').toString(),
          'https://www.facebook.com/profile.php?id=100012345678');
    });
  });
}
