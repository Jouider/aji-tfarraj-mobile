import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/features/profile/domain/face_check.dart';

/// STUB SIMULATEUR — NE PAS COMMITER.
/// ML Kit n'a pas de tranche arm64 pour le simulateur ; le vrai service est
/// dans /tmp/face_real.dart le temps de la prévisualisation.
class FaceDetectionService {
  Future<FaceCheck> check(String imagePath,
          {bool requireSmile = false}) async =>
      FaceCheck.ok;
}

final faceDetectionServiceProvider =
    Provider<FaceDetectionService>((ref) => FaceDetectionService());
