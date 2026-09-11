import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';
import 'package:aji_tfarraj/features/casting/domain/pose_check.dart';

/// Full-length shots are judged by body-pose detection, which is unreliable on
/// loose clothing. So nearly every verdict here is ADVICE the member can
/// override — and most of these tests pin what must NOT produce advice.
void main() {
  /// A person standing square to the camera: shoulders 80 apart, torso 100 long.
  PoseObservation standing({
    double shoulderSpan = 80,
    double nose = 0.99,
    double? leftAnkle = 0.95,
    double? rightAnkle = 0.95,
    double shoulders = 0.99,
    double hips = 0.99,
  }) {
    const cx = 500.0;
    return PoseObservation(
      nose: BodyPoint(cx, 150, nose),
      leftShoulder: BodyPoint(cx + shoulderSpan / 2, 250, shoulders),
      rightShoulder: BodyPoint(cx - shoulderSpan / 2, 250, shoulders),
      leftHip: const BodyPoint(cx + 30, 350, 0.99).withLikelihood(hips),
      rightHip: const BodyPoint(cx - 30, 350, 0.99).withLikelihood(hips),
      leftAnkle: leftAnkle == null ? null : BodyPoint(cx + 20, 800, leftAnkle),
      rightAnkle: rightAnkle == null ? null : BodyPoint(cx - 20, 800, rightAnkle),
    );
  }

  group('nobody there', () {
    test('no person refuses the shot — the only verdict that does', () {
      expect(evaluatePose(null, CastingPose.fullFront), PoseCheck.noPerson);
      expect(PoseCheck.noPerson.blocks, isTrue);
    });

    test('every other verdict only advises', () {
      for (final v in PoseCheck.values.where((v) => v != PoseCheck.noPerson)) {
        expect(v.blocks, isFalse, reason: '$v must be overridable');
      }
    });
  });

  test('a well-framed front shot passes', () {
    expect(evaluatePose(standing(), CastingPose.fullFront), PoseCheck.ok);
  });

  test('portraits are not judged here', () {
    expect(evaluatePose(standing(nose: 0.0), CastingPose.portrait), PoseCheck.ok);
  });

  group('framing', () {
    test('a head outside the frame is flagged', () {
      expect(evaluatePose(standing(nose: 0.2), CastingPose.fullFront),
          PoseCheck.headCut);
    });

    test('feet outside the frame are flagged', () {
      expect(
          evaluatePose(standing(leftAnkle: 0.1, rightAnkle: 0.2),
              CastingPose.fullFront),
          PoseCheck.feetCut);
    });

    /// Side-on, one ankle hides behind the other.
    test('one foot in the frame is enough', () {
      expect(
          evaluatePose(standing(leftAnkle: 0.1, rightAnkle: 0.9),
              CastingPose.fullFront),
          PoseCheck.ok);
    });

    test('ankles the detector did not report are not held against it', () {
      expect(
          evaluatePose(standing(leftAnkle: null, rightAnkle: null),
              CastingPose.fullFront),
          PoseCheck.ok);
    });

    test('the head is reported before the feet', () {
      expect(
          evaluatePose(standing(nose: 0.1, leftAnkle: 0.1, rightAnkle: 0.1),
              CastingPose.fullFront),
          PoseCheck.headCut);
    });
  });

  group('facing the camera', () {
    test('a front shot taken side-on is flagged', () {
      expect(evaluatePose(standing(shoulderSpan: 20), CastingPose.fullFront),
          PoseCheck.notFacing);
    });

    /// The ambiguous band is left alone: advice there would mostly be wrong.
    test('a three-quarter turn is not flagged as a front shot', () {
      expect(evaluatePose(standing(shoulderSpan: 50), CastingPose.fullFront),
          PoseCheck.ok);
    });
  });

  group('side-on', () {
    test('a profile shot taken from the front is flagged', () {
      expect(evaluatePose(standing(shoulderSpan: 80), CastingPose.fullProfile),
          PoseCheck.notSideways);
    });

    test('a real profile passes', () {
      expect(evaluatePose(standing(shoulderSpan: 15), CastingPose.fullProfile),
          PoseCheck.ok);
    });
  });

  group('from behind', () {
    /// Left and right are guesswork from behind, so only framing counts.
    test('orientation is not judged for the back shot', () {
      expect(evaluatePose(standing(shoulderSpan: 80), CastingPose.fullBack),
          PoseCheck.ok);
      expect(evaluatePose(standing(shoulderSpan: 10), CastingPose.fullBack),
          PoseCheck.ok);
    });

    test('but its framing still is', () {
      expect(
          evaluatePose(standing(leftAnkle: 0.1, rightAnkle: 0.1),
              CastingPose.fullBack),
          PoseCheck.feetCut);
    });
  });

  /// A sleeve or a scarf over the shoulders makes the ratio noise; noise must
  /// not turn into advice.
  test('orientation is skipped when shoulders or hips are unclear', () {
    expect(
        evaluatePose(standing(shoulderSpan: 10, shoulders: 0.3),
            CastingPose.fullFront),
        PoseCheck.ok);
    expect(
        evaluatePose(standing(shoulderSpan: 10, hips: 0.3),
            CastingPose.fullFront),
        PoseCheck.ok);
  });
}

extension on BodyPoint {
  BodyPoint withLikelihood(double inFrame) => BodyPoint(x, y, inFrame);
}
