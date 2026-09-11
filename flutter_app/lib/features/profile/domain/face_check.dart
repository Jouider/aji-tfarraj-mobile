import 'dart:ui' show Rect;

/// What the detector saw of one face, reduced to what the check needs.
///
/// Kept apart from ML Kit's own type on purpose: the rules below decide whether
/// someone's photo is refused, so they must be testable without a camera, a
/// phone or a native plugin.
class FaceObservation {
  final Rect box;

  /// Left/right turn of the head, in degrees. Null when the detector could not
  /// tell — and then it is not held against the photo.
  final double? yaw;

  /// Sideways tilt of the head, in degrees.
  final double? roll;

  final double? leftEyeOpen;
  final double? rightEyeOpen;

  /// Smile probability, 0–1. Only consulted when a smile is asked for.
  final double? smile;

  const FaceObservation({
    required this.box,
    this.yaw,
    this.roll,
    this.leftEyeOpen,
    this.rightEyeOpen,
    this.smile,
  });
}

/// The verdict on a profile photo, in the order it is worth telling someone.
enum FaceCheck {
  ok,

  /// Nothing that looks like a face.
  noFace,

  /// A face, but so far away it is useless to the door — "come closer".
  tooSmall,

  /// Another person in the photo, nearly as close as the first.
  multipleFaces,

  /// Head turned or tilted away from the camera.
  notFacing,

  /// Both eyes clearly shut.
  eyesClosed,

  /// Asked for a smile, got none. Only ever produced when a smile is
  /// requested — the casting "portrait souriant" — never for a profile photo.
  notSmiling,
}

/// Where the lines are drawn. Every one of them errs towards accepting.
///
/// A photo refused by mistake is a person stuck at the profile screen; a
/// slightly imperfect photo is still one the door can use. So each threshold
/// rejects only what is plainly unusable.
abstract final class FaceCheckRules {
  /// The main face must be at least this wide relative to the image. Same
  /// value the check used before — it now says "come closer" instead of
  /// "no face", but refuses no more photos than it did.
  static const double minFaceWidthRatio = 0.15;

  /// A second face at least half the width of the main one is someone else
  /// standing in the photo. A smaller one is a passer-by in the background.
  static const double secondFaceRatio = 0.5;

  /// Degrees of turn or tilt allowed. Wide on purpose: a slight angle is a
  /// normal photo, a head turned a third of the way is not an ID photo.
  static const double maxYaw = 25;
  static const double maxRoll = 25;

  /// Below this, an eye counts as shut. Low so that narrow eyes, glasses and
  /// strong light are not mistaken for a blink.
  static const double closedEye = 0.15;

  /// Below this, "smile please". Low, because a closed-mouth smile reads well
  /// under 0.5 and is still a smile.
  static const double minSmile = 0.3;
}

/// Decides on a photo from what the detector saw.
///
/// [imageWidth] is the photo's width in the same pixels as the boxes. When it
/// is unknown the size rule is skipped rather than guessed at.
FaceCheck evaluateFaces(
  List<FaceObservation> faces, {
  double? imageWidth,
  bool requireSmile = false,
}) {
  if (faces.isEmpty) return FaceCheck.noFace;

  final byWidth = [...faces]
    ..sort((a, b) => b.box.width.compareTo(a.box.width));
  final main = byWidth.first;

  if (imageWidth != null &&
      imageWidth > 0 &&
      main.box.width / imageWidth < FaceCheckRules.minFaceWidthRatio) {
    return FaceCheck.tooSmall;
  }

  if (byWidth.length > 1 &&
      byWidth[1].box.width >= main.box.width * FaceCheckRules.secondFaceRatio) {
    return FaceCheck.multipleFaces;
  }

  if ((main.yaw?.abs() ?? 0) > FaceCheckRules.maxYaw ||
      (main.roll?.abs() ?? 0) > FaceCheckRules.maxRoll) {
    return FaceCheck.notFacing;
  }

  // Both eyes, and both must be known: one shut eye is a wink or a squint in
  // the sun, and a missing reading is not evidence of anything.
  final left = main.leftEyeOpen;
  final right = main.rightEyeOpen;
  if (left != null &&
      right != null &&
      left < FaceCheckRules.closedEye &&
      right < FaceCheckRules.closedEye) {
    return FaceCheck.eyesClosed;
  }

  // Last: a smile is the least important thing wrong with a photo, and a
  // missing reading is not held against it.
  if (requireSmile &&
      main.smile != null &&
      main.smile! < FaceCheckRules.minSmile) {
    return FaceCheck.notSmiling;
  }

  return FaceCheck.ok;
}
