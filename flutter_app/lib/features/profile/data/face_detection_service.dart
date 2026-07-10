import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// On-device face detection (Google ML Kit) used to validate that a captured
/// avatar actually contains a face before it's uploaded. Fully offline.
class FaceDetectionService {
  /// Returns true if at least one face is detected in the image at [imagePath].
  ///
  /// Fails *open* (returns true) on a detector error so a transient ML Kit
  /// failure never blocks a user with a valid photo — the check only rejects
  /// when detection succeeds and finds no face.
  Future<bool> hasFace(String imagePath) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        // Ignore tiny faces in the background — the avatar should be the person.
        minFaceSize: 0.15,
      ),
    );
    try {
      final faces =
          await detector.processImage(InputImage.fromFilePath(imagePath));
      return faces.isNotEmpty;
    } catch (e) {
      debugPrint('[FaceDetection] error: $e');
      return true; // fail open
    } finally {
      await detector.close();
    }
  }
}

final faceDetectionServiceProvider =
    Provider<FaceDetectionService>((ref) => FaceDetectionService());
