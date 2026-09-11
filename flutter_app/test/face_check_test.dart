import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/features/profile/domain/face_check.dart';

/// These rules decide whether someone's photo is refused. A wrong refusal
/// leaves a person stuck at the profile screen, so most of these tests pin what
/// must still be ACCEPTED.
void main() {
  const imageWidth = 1000.0;

  FaceObservation face({
    double width = 400,
    double x = 300,
    double? yaw = 0,
    double? roll = 0,
    double? left = 0.9,
    double? right = 0.9,
  }) =>
      FaceObservation(
        box: Rect.fromLTWH(x, 200, width, width * 1.2),
        yaw: yaw,
        roll: roll,
        leftEyeOpen: left,
        rightEyeOpen: right,
      );

  FaceCheck check(List<FaceObservation> faces, {double? width = imageWidth}) =>
      evaluateFaces(faces, imageWidth: width);

  test('a clear, frontal, open-eyed face passes', () {
    expect(check([face()]), FaceCheck.ok);
  });

  test('no face is refused', () {
    expect(check([]), FaceCheck.noFace);
  });

  group('distance', () {
    test('a face too far away is told to come closer', () {
      expect(check([face(width: 120)]), FaceCheck.tooSmall);
    });

    /// The size threshold is the one the app already used, so the new check
    /// refuses no more photos for size than before — it only explains better.
    test('right at the old threshold still passes', () {
      expect(check([face(width: 150)]), FaceCheck.ok);
    });

    test('an unknown image size skips the size rule instead of guessing', () {
      expect(check([face(width: 20)], width: null), FaceCheck.ok);
    });
  });

  group('other people', () {
    test('a second person as close as the first is refused', () {
      expect(check([face(width: 400), face(width: 350, x: 0)]),
          FaceCheck.multipleFaces);
    });

    /// Photos are taken in streets, cafés and at the studio door.
    test('a small face in the background does not count', () {
      expect(check([face(width: 400), face(width: 90, x: 0)]), FaceCheck.ok);
    });

    test('the largest face is the one judged, whatever the order', () {
      expect(check([face(width: 90, x: 0), face(width: 400)]), FaceCheck.ok);
    });
  });

  group('looking at the camera', () {
    test('a head turned well away is refused', () {
      expect(check([face(yaw: 40)]), FaceCheck.notFacing);
      expect(check([face(yaw: -40)]), FaceCheck.notFacing);
    });

    test('a head tilted well over is refused', () {
      expect(check([face(roll: 35)]), FaceCheck.notFacing);
    });

    test('a slight angle is a normal photo and passes', () {
      expect(check([face(yaw: 15, roll: -12)]), FaceCheck.ok);
    });

    test('an angle the detector did not report is not held against it', () {
      expect(check([face(yaw: null, roll: null)]), FaceCheck.ok);
    });
  });

  group('eyes', () {
    test('both eyes clearly shut is refused', () {
      expect(check([face(left: 0.05, right: 0.08)]), FaceCheck.eyesClosed);
    });

    /// A squint in the sun, a wink, one eye behind a strand of hair.
    test('one eye shut is not a blink', () {
      expect(check([face(left: 0.05, right: 0.9)]), FaceCheck.ok);
    });

    /// Narrow eyes and glasses read low but open.
    test('eyes that read low but not shut pass', () {
      expect(check([face(left: 0.25, right: 0.3)]), FaceCheck.ok);
    });

    test('a missing eye reading is not evidence of anything', () {
      expect(check([face(left: null, right: 0.05)]), FaceCheck.ok);
    });
  });

  test('distance is reported before anything else', () {
    // A far-away face will also read badly on angles; "come closer" is the
    // advice that fixes everything at once.
    expect(check([face(width: 100, yaw: 40, left: 0.0, right: 0.0)]),
        FaceCheck.tooSmall);
  });

  /// The casting "portrait souriant". A smile is asked for there and nowhere
  /// else — a profile photo is never refused for not smiling.
  group('smile, when asked for', () {
    FaceObservation smiling(double? smile) => FaceObservation(
          box: const Rect.fromLTWH(300, 200, 400, 480),
          yaw: 0,
          roll: 0,
          leftEyeOpen: 0.9,
          rightEyeOpen: 0.9,
          smile: smile,
        );

    test('no smile is refused when one is asked for', () {
      expect(
          evaluateFaces([smiling(0.1)],
              imageWidth: imageWidth, requireSmile: true),
          FaceCheck.notSmiling);
    });

    /// A closed-mouth smile reads well under 0.5 and is still a smile.
    test('a modest smile passes', () {
      expect(
          evaluateFaces([smiling(0.4)],
              imageWidth: imageWidth, requireSmile: true),
          FaceCheck.ok);
    });

    test('a missing smile reading is not held against it', () {
      expect(
          evaluateFaces([smiling(null)],
              imageWidth: imageWidth, requireSmile: true),
          FaceCheck.ok);
    });

    test('a profile photo is never refused for not smiling', () {
      expect(evaluateFaces([smiling(0.0)], imageWidth: imageWidth),
          FaceCheck.ok);
    });

    test('a real problem is reported before the smile', () {
      final shut = FaceObservation(
        box: const Rect.fromLTWH(300, 200, 400, 480),
        leftEyeOpen: 0.05,
        rightEyeOpen: 0.05,
        smile: 0.0,
      );
      expect(
          evaluateFaces([shut], imageWidth: imageWidth, requireSmile: true),
          FaceCheck.eyesClosed);
    });
  });
}
