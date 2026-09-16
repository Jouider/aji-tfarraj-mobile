import 'package:aji_tfarraj/app/localization/app_locale.dart';

/// What a tutorial clip walks the member through. [key] is the server's name
/// for it in `GET /api/app-config → tutorials`.
enum TutorialTopic {
  /// Completing the profile: photo, name, birthday, city, phone.
  profile('profile'),

  /// Booking from a charge public's invitation link, through to the ticket.
  reservationReferral('reservation_referral');

  const TutorialTopic(this.key);

  final String key;
}

/// One clip, in one language.
class TutorialClip {
  const TutorialClip({required this.video, this.poster, this.duration});

  final Uri video;

  /// Shown while the video loads.
  final Uri? poster;

  /// Told to the member before they commit to watching.
  final Duration? duration;

  /// Null when the entry cannot be played — no URL, or not a web address.
  static TutorialClip? tryParse(Object? json) {
    if (json is! Map) return null;

    final video = _webUri(json['video_url']);
    if (video == null) return null;

    final seconds = json['duration'];

    return TutorialClip(
      video: video,
      poster: _webUri(json['poster_url']),
      duration: seconds is num && seconds > 0
          ? Duration(seconds: seconds.round())
          : null,
    );
  }

  static Uri? _webUri(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;
    return uri.scheme == 'https' || uri.scheme == 'http' ? uri : null;
  }
}

/// Every clip the server announced, by topic and language.
class Tutorials {
  const Tutorials(this._clips);

  /// An older server, a failed request, or no clips yet: nothing to show.
  static const none = Tutorials({});

  final Map<TutorialTopic, Map<String, TutorialClip>> _clips;

  /// Reads the `tutorials` block of `GET /api/app-config`. Anything unexpected
  /// is skipped rather than failing — without clips the app simply shows no
  /// video buttons.
  factory Tutorials.fromAppConfig(Object? json) {
    if (json is! Map) return none;
    final raw = json['tutorials'];
    // PHP encodes an empty array as `[]`, not `{}`.
    if (raw is! Map) return none;

    final clips = <TutorialTopic, Map<String, TutorialClip>>{};

    for (final topic in TutorialTopic.values) {
      final languages = raw[topic.key];
      if (languages is! Map) continue;

      final byLanguage = <String, TutorialClip>{};
      languages.forEach((language, entry) {
        final clip = TutorialClip.tryParse(entry);
        if (language is String && clip != null) byLanguage[language] = clip;
      });

      if (byLanguage.isNotEmpty) clips[topic] = byLanguage;
    }

    return Tutorials(clips);
  }

  /// The clip in the member's language — or in the other one when only that
  /// exists: the screens are the same, and a clip helps more than none.
  TutorialClip? clipFor(TutorialTopic topic, AppLocale locale) {
    final byLanguage = _clips[topic];
    if (byLanguage == null) return null;
    return byLanguage[locale.languageCode] ?? byLanguage.values.first;
  }
}

/// "0:49" — how long the clip asks of the member.
String formatClipDuration(Duration? duration) {
  if (duration == null) return '';
  final minutes = duration.inMinutes;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
