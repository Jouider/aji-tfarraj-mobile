/// The shots a casting book is made of.
///
/// The poses are fixed, and that is the point: whoever is choosing looks at
/// forty books at once, and can only compare them if everyone sent the same
/// shots. Left free, the choice is made on who had the better photographer.
///
/// The keys match the server's (`CastingPhoto::POSES`) — they are sent as-is.
enum CastingPose {
  fullFront('full_front'),
  fullProfile('full_profile'),
  portrait('portrait'),
  portraitSmile('portrait_smile');

  // Le plein pied de dos n'est plus demandé : ce n'est pas une photo qu'on
  // demande à un membre pour un book. Le serveur le refuse, et [fromKey]
  // ignore une ancienne photo qui porterait encore cette clé.

  const CastingPose(this.key);

  final String key;

  static CastingPose? fromKey(String? key) {
    for (final pose in CastingPose.values) {
      if (pose.key == key) return pose;
    }
    return null;
  }

  /// Without these three there is no silhouette, no profile and no face, so a
  /// book cannot be judged at all.
  static const required = [
    CastingPose.fullFront,
    CastingPose.fullProfile,
    CastingPose.portrait,
  ];

  bool get isRequired => required.contains(this);

  /// Head-and-shoulders shots frame differently from full-length ones, so the
  /// camera guide has to know which it is drawing.
  bool get isFullLength =>
      this == CastingPose.fullFront || this == CastingPose.fullProfile;
}
