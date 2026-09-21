import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';
import 'package:aji_tfarraj/features/tutorials/data/tutorials_repository.dart';
import 'package:aji_tfarraj/features/tutorials/domain/tutorial.dart';

/// La démonstration vidéo de chaque pose du book : la bonne photo, et les
/// erreurs qui la rendent inutilisable. Montrée avant que la caméra ne
/// s'ouvre, là où la personne lit encore.
///
/// Servie par `GET /api/app-config → pose_guides`, une par pose, sans langue :
/// les clips sont muets, ils montrent sans raconter.
class PoseGuides {
  const PoseGuides(this._clips);

  static const none = PoseGuides({});

  final Map<CastingPose, TutorialClip> _clips;

  /// Ce qui ne se lit pas est ignoré plutôt que de faire échouer le guide :
  /// sans démonstration, le guide reste ce qu'il était, du texte.
  factory PoseGuides.fromAppConfig(Object? json) {
    if (json is! Map) return none;
    final raw = json['pose_guides'];
    // PHP encode un tableau vide en `[]`, pas en `{}`.
    if (raw is! Map) return none;

    final clips = <CastingPose, TutorialClip>{};
    raw.forEach((key, entry) {
      final pose = CastingPose.fromKey(key is String ? key : null);
      final clip = TutorialClip.tryParse(entry);
      if (pose != null && clip != null) clips[pose] = clip;
    });

    return PoseGuides(clips);
  }

  TutorialClip? forPose(CastingPose pose) => _clips[pose];
}

final poseGuidesProvider = FutureProvider<PoseGuides>(
  (ref) async =>
      PoseGuides.fromAppConfig(await ref.watch(appConfigJsonProvider.future)),
);

/// La démonstration d'une pose, ou null tant qu'elle charge, en cas d'échec,
/// ou quand le serveur n'en a pas — le guide s'en passe alors.
final poseGuideClipProvider =
    Provider.family<TutorialClip?, CastingPose>((ref, pose) {
  final guides = ref.watch(poseGuidesProvider).valueOrNull ?? PoseGuides.none;
  return guides.forPose(pose);
});
