import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';
import 'package:aji_tfarraj/features/casting/domain/pose_check.dart';

/// STUB SIMULATEUR — NE PAS COMMITER. Voir /tmp/body_real.dart.
class BodyPoseService {
  Future<PoseCheck> check(String imagePath, CastingPose pose) async =>
      PoseCheck.ok;
}

final bodyPoseServiceProvider =
    Provider<BodyPoseService>((ref) => BodyPoseService());
