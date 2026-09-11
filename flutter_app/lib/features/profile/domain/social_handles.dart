/// The social networks a member can add. Kept to three on purpose.
enum SocialPlatform {
  instagram('instagram'),
  tiktok('tiktok'),
  facebook('facebook');

  const SocialPlatform(this.key);

  /// The API field name.
  final String key;
}

/// Turns whatever a member typed into a social account we can store and open.
///
/// People type "@nom", "Nom", or paste a whole profile link copied from the
/// app — all three must end up as the same value. These are the same rules the
/// server applies (app/Support/SocialHandles.php); the app runs them first so a
/// mistake is caught in the field, and the server runs them again because it
/// decides what is stored.
abstract final class SocialHandles {
  /// First path segments that are not a username (posts, reels, menus).
  static const _instagramReserved = {
    'p', 'reel', 'reels', 'tv', 'explore', 'accounts', 'direct',
  };

  static const _facebookReserved = {
    'share', 'sharer', 'sharer.php', 'groups', 'pages', 'events', 'watch',
    'marketplace', 'story.php', 'photo.php', 'permalink.php', 'people',
    'login', 'home.php',
  };

  static final _link = RegExp(
      r'(^|\.)(instagram\.com|tiktok\.com|facebook\.com|fb\.com)(/|$)');

  /// The cleaned value, or null when the field is empty (which clears it).
  ///
  /// A link that does not point at a profile — a post, a short link — comes
  /// back as-is, and [isValid] then refuses it.
  static String? normalize(SocialPlatform platform, String? raw) {
    final value = (raw ?? '').replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (value.isEmpty) return null;

    if (value.startsWith('http') || _link.hasMatch(value)) {
      return _fromLink(platform, value);
    }

    return value.replaceFirst(RegExp(r'^@+'), '');
  }

  static String _fromLink(SocialPlatform platform, String link) {
    final uri = Uri.tryParse(link.startsWith('http') ? link : 'https://$link');
    if (uri == null) return link;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    final first = segments.isEmpty ? '' : segments.first;
    String? handle;

    switch (platform) {
      case SocialPlatform.instagram:
        if (first == 'stories') {
          handle = segments.length > 1 ? segments[1] : null;
        } else if (!_instagramReserved.contains(first)) {
          handle = first;
        }
      case SocialPlatform.tiktok:
        for (final segment in segments) {
          if (segment.startsWith('@')) {
            handle = segment.substring(1);
            break;
          }
        }
      case SocialPlatform.facebook:
        if (first == 'profile.php') {
          handle = uri.queryParameters['id'];
        } else if (!_facebookReserved.contains(first)) {
          handle = first;
        }
    }

    return (handle == null || handle.isEmpty)
        ? link
        : handle.replaceFirst(RegExp(r'^@+'), '');
  }

  static bool isValid(SocialPlatform platform, String handle) =>
      switch (platform) {
        SocialPlatform.instagram =>
          RegExp(r'^[a-z0-9._]{1,30}$').hasMatch(handle),
        SocialPlatform.tiktok => RegExp(r'^[a-z0-9._]{2,24}$').hasMatch(handle),
        // A username, or the numeric id of a profile without one.
        SocialPlatform.facebook =>
          RegExp(r'^([a-z0-9.]{5,50}|\d{5,20})$').hasMatch(handle),
      };

  /// The public profile, for the "Vérifier" button. Opening it hands off to the
  /// network's own app when it is installed.
  static Uri profileUri(SocialPlatform platform, String handle) =>
      switch (platform) {
        SocialPlatform.instagram =>
          Uri.parse('https://www.instagram.com/$handle/'),
        SocialPlatform.tiktok => Uri.parse('https://www.tiktok.com/@$handle'),
        SocialPlatform.facebook => RegExp(r'^\d+$').hasMatch(handle)
            ? Uri.parse('https://www.facebook.com/profile.php?id=$handle')
            : Uri.parse('https://www.facebook.com/$handle'),
      };
}
