import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';

/// One body point as the detector placed it.
class BodyPoint {
  final double x;
  final double y;

  /// How likely the point is to be INSIDE the photo — ML Kit's in-frame
  /// likelihood. It says nothing about whether the point is hidden behind a
  /// sleeve, which is why the checks below lean on framing, not visibility.
  final double inFrame;

  const BodyPoint(this.x, this.y, this.inFrame);
}

/// The handful of points the checks need. Null when the detector gave nothing.
class PoseObservation {
  final BodyPoint? nose;
  final BodyPoint? leftShoulder;
  final BodyPoint? rightShoulder;
  final BodyPoint? leftHip;
  final BodyPoint? rightHip;
  final BodyPoint? leftAnkle;
  final BodyPoint? rightAnkle;

  const PoseObservation({
    this.nose,
    this.leftShoulder,
    this.rightShoulder,
    this.leftHip,
    this.rightHip,
    this.leftAnkle,
    this.rightAnkle,
  });
}

/// The verdict on a full-length casting shot.
enum PoseCheck {
  ok,

  /// Nobody in the photo. The ONLY verdict that refuses the shot.
  noPerson,

  /// The top of the person is outside the frame.
  headCut,

  /// The feet are outside the frame — the commonest full-length mistake.
  feetCut,

  /// Asked for the front, got something turned away.
  notFacing,

  /// Asked for the side, got something closer to the front.
  notSideways,
}

extension PoseCheckBlocking on PoseCheck {
  /// Body-pose detection is unreliable on loose clothing — djellaba, abaya —
  /// which many members wear. So it advises and never decides, except when
  /// there is plainly nobody there.
  bool get blocks => this == PoseCheck.noPerson;
}

abstract final class PoseCheckRules {
  /// A point counts as in the photo from this in-frame likelihood.
  static const double inFrame = 0.5;

  /// Shoulder span over torso length. Facing the camera it sits around 0.7–1;
  /// side-on, shoulders overlap and it drops to 0.1–0.3. A three-quarter turn
  /// lands near 0.5, so both thresholds leave that ambiguous band alone.
  static const double minFrontRatio = 0.45;
  static const double maxProfileRatio = 0.4;
}

/// Judges a full-length shot from what the detector saw.
///
/// [body] is null when the detector found no person at all. Portraits are not
/// judged here — the face check handles them.
PoseCheck evaluatePose(PoseObservation? body, CastingPose pose) {
  if (body == null) return PoseCheck.noPerson;
  if (!pose.isFullLength) return PoseCheck.ok;

  bool clear(BodyPoint? p) => p != null && p.inFrame >= PoseCheckRules.inFrame;

  // A point the detector did not report is not held against the photo.
  if (body.nose != null && !clear(body.nose)) return PoseCheck.headCut;

  // One foot is enough: side-on, one ankle often hides behind the other.
  final ankles = [body.leftAnkle, body.rightAnkle].whereType<BodyPoint>();
  if (ankles.isNotEmpty && !ankles.any(clear)) return PoseCheck.feetCut;

  // From behind, left and right are guesswork for the detector, so the back
  // shot is judged on framing alone.
  if (pose == CastingPose.fullBack) return PoseCheck.ok;

  final ls = body.leftShoulder;
  final rs = body.rightShoulder;
  final lh = body.leftHip;
  final rh = body.rightHip;

  // Orientation only when all four anchors are clearly placed — otherwise the
  // ratio is noise, and noise must not produce advice.
  if (!clear(ls) || !clear(rs) || !clear(lh) || !clear(rh)) return PoseCheck.ok;

  final span = (ls!.x - rs!.x).abs();
  final torso = ((ls.y + rs.y) / 2 - (lh!.y + rh!.y) / 2).abs();
  if (torso <= 0) return PoseCheck.ok;

  final ratio = span / torso;

  if (pose == CastingPose.fullFront && ratio < PoseCheckRules.minFrontRatio) {
    return PoseCheck.notFacing;
  }
  if (pose == CastingPose.fullProfile && ratio > PoseCheckRules.maxProfileRatio) {
    return PoseCheck.notSideways;
  }

  return PoseCheck.ok;
}
