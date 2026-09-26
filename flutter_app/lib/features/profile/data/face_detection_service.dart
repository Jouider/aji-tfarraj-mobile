import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:aji_tfarraj/features/profile/domain/face_check.dart';

/// On-device face check (Google ML Kit), run on a profile photo before upload.
///
/// Fully offline: nothing about the face leaves the phone, and no biometric
/// template is computed or kept. That is the difference with the server's
/// duplicate search, whose embeddings are biometric data under law 09-08 and
/// need CNDP authorisation — this check needs neither.
///
/// The rules themselves live in [evaluateFaces], apart from ML Kit, so they can
/// be tested without a device.
class FaceDetectionService {
  /// The verdict on the photo at [imagePath].
  ///
  /// Fails OPEN: a detector error returns [FaceCheck.ok], so a transient ML Kit
  /// failure never blocks someone with a valid photo. The check only refuses
  /// when detection worked and found a real problem.
  ///
  /// [requireSmile] is for the casting "portrait souriant" only.
  Future<FaceCheck> check(String imagePath, {bool requireSmile = false}) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        // Accurate rather than fast: this runs once, after the shutter, and a
        // wrong angle reading here is a wrong refusal.
        performanceMode: FaceDetectorMode.accurate,
        // Needed for the eye-open probabilities.
        enableClassification: true,
        // Deliberately below the size rule, so a face that is merely too far
        // away is still found — and the person is told to come closer rather
        // than that there is no face at all.
        minFaceSize: 0.1,
      ),
    );

    try {
      final faces =
          await detector.processImage(InputImage.fromFilePath(imagePath));

      return evaluateFaces(
        faces
            .map((f) => FaceObservation(
                  box: f.boundingBox,
                  yaw: f.headEulerAngleY,
                  roll: f.headEulerAngleZ,
                  leftEyeOpen: f.leftEyeOpenProbability,
                  rightEyeOpen: f.rightEyeOpenProbability,
                  smile: f.smilingProbability,
                ))
            .toList(),
        imageWidth: await _referenceWidth(imagePath),
        requireSmile: requireSmile,
      );
    } catch (e) {
      debugPrint('[FaceDetection] error: $e');
      return FaceCheck.ok; // fail open
    } finally {
      await detector.close();
    }
  }

  /// The photo's SHORTER side, read from its header without decoding pixels.
  ///
  /// Shorter rather than width: if the file still carries an orientation tag,
  /// the header's width and height can come out swapped relative to what the
  /// detector saw, and a normal face would then look "too small". For a
  /// portrait photo the shorter side is the width anyway; for anything else it
  /// only ever makes the size rule more lenient. Null when unreadable — the
  /// size rule is then skipped.
  static Future<double?> _referenceWidth(String path) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(
          await File(path).readAsBytes());
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      return math.min(descriptor.width, descriptor.height).toDouble();
    } catch (_) {
      return null;
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}

final faceDetectionServiceProvider =
    Provider<FaceDetectionService>((ref) => FaceDetectionService());
