import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';
import 'package:aji_tfarraj/features/casting/domain/pose_check.dart';

/// Reads the body in a full-length casting shot, on the phone (Google ML Kit).
///
/// Like the face check: nothing leaves the device and nothing is kept. The
/// rules live in [evaluatePose], apart from ML Kit, so they can be tested
/// without a device.
class BodyPoseService {
  /// The verdict on the full-length shot at [imagePath].
  ///
  /// Fails OPEN: a detector error returns [PoseCheck.ok]. A crash inside the
  /// detector must never be the reason a shot is questioned.
  Future<PoseCheck> check(String imagePath, CastingPose pose) async {
    final detector = PoseDetector(
      options: PoseDetectorOptions(
        // One still photo, judged once after the shutter: the accurate model
        // and single-image mode, rather than the streaming defaults.
        model: PoseDetectionModel.accurate,
        mode: PoseDetectionMode.single,
      ),
    );

    try {
      final poses =
          await detector.processImage(InputImage.fromFilePath(imagePath));

      // ML Kit reads one person — the most prominent. An empty result is the
      // only thing that means "nobody there".
      return evaluatePose(poses.isEmpty ? null : _observe(poses.first), pose);
    } catch (e) {
      debugPrint('[BodyPose] error: $e');
      return PoseCheck.ok; // fail open
    } finally {
      await detector.close();
    }
  }

  static PoseObservation _observe(Pose pose) {
    BodyPoint? point(PoseLandmarkType type) {
      final landmark = pose.landmarks[type];
      return landmark == null
          ? null
          : BodyPoint(landmark.x, landmark.y, landmark.likelihood);
    }

    return PoseObservation(
      nose: point(PoseLandmarkType.nose),
      leftShoulder: point(PoseLandmarkType.leftShoulder),
      rightShoulder: point(PoseLandmarkType.rightShoulder),
      leftHip: point(PoseLandmarkType.leftHip),
      rightHip: point(PoseLandmarkType.rightHip),
      leftAnkle: point(PoseLandmarkType.leftAnkle),
      rightAnkle: point(PoseLandmarkType.rightAnkle),
    );
  }
}

final bodyPoseServiceProvider =
    Provider<BodyPoseService>((ref) => BodyPoseService());
